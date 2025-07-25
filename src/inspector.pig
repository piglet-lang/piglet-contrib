(module inspector
  "Inspect values in a browser element"
  (:import
    [dom :from piglet:dom]
    [css :from piglet:css]))

(def styles
  [[".piglet-inspector" {:background-color "white"
                         :cursor "pointer"
                         :display "flex"
                         :flex-grow "1"
                         :font-family "monospace"}
    [:.prefix {:color "#999"}]
    [:.value {:color "#3b758a"}]]
   [:.node {:padding-left "1rem"}]
   [:.expanded {:display "flex" :flex-direction "column"}]])

(defn expandable? [o]
  (and (not (string? o))
    (or
      (satisfies? Seqable o)
      (object? o))))

(declare collapsed inspector)

(defn expanded [nid k o]
  [:div.node.expanded
   {:id nid}
   [:div.heading
    {:on-click (fn []
                 (dom:replace (dom:query-one (str "#" nid))
                   (dom:dom [collapsed nid k o])))}
    [:span.prefix "⏷ "]
    (when k
      [:span.value.key k " "])
    [:span.value (type-name o)]]
   [:div.body
    (if (or (satisfies? DictLike o) (object? o))
      (for [[k v] o]
        [inspector k v])
      (for [v o]
        [inspector v]))]])

(defn collapsed
  ([nid k o]
    [:div.node.collapsed
     {:id nid
      :on-click (fn []
                  (dom:replace (dom:query-one (str "#" nid))
                    (dom:dom [expanded nid k o])))}
     [:span.prefix
      (if (expandable? o)
        "⏵ "
        "  ")]
     (when k [:span.value.key k (when-not (keyword? k) ":") " "])
     [:span.value
      (if (expandable? o)
        (type-name o)
        (print-str o))]]))

(defn inspector
  ([k v]
    [:div.piglet-inspector
     [collapsed (gensym "n") k v]])
  ([o]
    [:div.piglet-inspector
     [collapsed (gensym "n") nil o]]))
