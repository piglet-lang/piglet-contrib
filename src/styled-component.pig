(module styled-component
  "Macro to define components with related styles")

(def component-styles (box {}))

(defmacro defc
  "Poor man's styled component macro

  - classnames aren't namespaced"
  [name & forms]
  (let [[doc & forms] (if (string? first forms) forms (cons nil forms))
        styles (butlast forms)
        fntail (last forms)]
    (swap! component-styles assoc name (into [(str "." name)] styles))
    `(defn ~name ~@(when doc [doc]) ~(first fntail)
       (loop [[tag# & ch#] (do ~@(rest fntail))]
         (if (fn? tag#)
           ;; FIXME: seems piglet gets confused about recur in macros
           (~'recur (apply tag# ch#))
           (into [(keyword (str (name tag#) "." '~name))] ch#))))))

(defn all-styles []
  (vals @component-styles))

(comment

  (defc page-header
    {:margin-top "0"
     :margin-bottom "2rem"
     :padding "1rem 0 1rem 0"
     :border-bottom "3px solid var(--theme-color-accent)"}
    ([& children]
      (into [:header] children)))

  (all-styles)

  )
