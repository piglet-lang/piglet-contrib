(module session
  "HTTP session handling"
  (:import
    [str :from piglet:string]
    [redis :from "redis"]))

(def cookie-octet
  ;; RFC 6265
  ;; cookie-octet = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
  ;; US-ASCII characters excluding CTLs, whitespace DQUOTE, comma,
  ;; semicolon, and backslash
  "[-!#$%&'\\(\\)\\*\\+\\./0-9:<=>?@A-Z\\[\\]^_`a-z\\{\\|\\}~]")

(def token
  ;; HTTP Token, RFC 2616, section 2.2
  ;; US-ASCII characters 32-126 excluding separators
  "[-!\"#$%&'\\*\\+\\.0-9A-Z^_`a-z]")

(def re-cookie
  (js:RegExp. (str "(" token "+)=(" cookie-octet "+|\\\"" cookie-octet "+\\\")")))

(defn redis-client []
  (let [c (redis:createClient)]
    (.on c "error" (fn [e] (println "Redis Client Error" e)))
    (.connect c)
    c))

(def session-key "piglet-session")

(defn rand-session-id []
  (apply str
    (take 40
      (repeatedly
        #(nth
           "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
           (rand-int 62))))))

(defn one-year-from-now []
  (let [d (js:Date.)]
    (.setFullYear d (inc (.getFullYear d)))
    (.toUTCString d)))

(defn wrap-session
  "Basic session middleware, just enough to get us going

  Return a `:session` key in the response to set session data. Session data is
  returned in the request under `:session`. Return `:session nil` to clear the
  session."
  [handler]
  (let [redis (redis-client)]
    (fn ^:async [req]
      (let [cookie-header (get-in req [:headers "cookie"])
            cookies (and cookie-header (re-seq re-cookie cookie-header))
            session-id (some (fn [[_ k v]]
                               (when (= session-key k)
                                 (if (= "\"" (first v))
                                   (str:subs v 1 (dec (count v)))
                                   v)))
                         cookies)
            redis-key (str "session:" session-id)
            session-data (when session-id (await (.get redis redis-key)))
            session-data (and session-data (read-string session-data))
            session-id (or session-id (rand-session-id))
            redis-key (str "session:" session-id)
            res (await (handler (cond-> req session-data (assoc :session session-data))))
            session-data-new (:session res)]
        (when (has-key? res :session)
          (cond
            (nil? session-data-new)
            (await (.del redis redis-key))
            (not= session-data session-data-new)
            (await (.set redis redis-key (print-str session-data-new)))))
        (assoc-in res [:headers "Set-Cookie"]
          (if (and (has-key? res :session) (nil? session-data-new))
            (str session-key "="  "; HttpOnly; Secure; Expires=" (.toUTCString (js:Date. 0)))
            (str session-key "=" session-id "; HttpOnly; Secure; Expires=" (one-year-from-now))))))))
