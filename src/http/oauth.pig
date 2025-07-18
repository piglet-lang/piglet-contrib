(module http/oauth
  "OAuth2 code exchange")

(defn query-params [kvs]
  (str "?" (js:URLSearchParams. kvs)))

(defn start-auth-flow-url
  "Open a browser to start the auth flow"
  [{:keys [client-id authorization-url redirect-url]}]
  (str authorization-url
    (query-params {"client_id" client-id
                   "redirect_uri" redirect-url
                   "response_type" "code"
                   "scope" "identify guilds"})))

(defn ^:async exchange-code!
  "Final step, exchange the code for an access_token / refresh_token"
  [{:keys [token-url redirect-url client-id client-secret]} code]
  (.json
    (await
      (js:fetch
        token-url
        #js {:method "POST"
             :headers {"content-type" "application/x-www-form-urlencoded"}
             :body (str (js:URLSearchParams.
                          {"grant_type" "authorization_code"
                           "code" code
                           "redirect_uri" redirect-url
                           "client_id" client-id
                           "client_secret" client-secret}))}))))
