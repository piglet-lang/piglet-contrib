(module middleware
  (:import [str :from piglet:string]))

(defn wrap-log [handler]
  (fn ^:async [req]
    (let [res (await (handler req))]
      (println (str:upcase (name (:method req))) (:path req) (str "[" (:status res) "]"))
      ;; (doseq [[k v] (:headers req)]
      ;;   (println (str k ":") v))
      ;; (println "----")
      ;; (doseq [[k v] (:headers res)]
      ;;   (println (str k ":") v))
      res)))
