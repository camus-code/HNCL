(in-package :hncl)

(def br (? (n 1))
  "Prints N break line tags."
  (repeat n (pr "<br>"))
  (prn))

(def br2 ()
  "Prints 2 break line tags."
  (prn "<br><br>"))

(mac center    body `(tag center ,@body))
(mac underline body `(tag u ,@body))
(mac tab       body `(tag (table border 0) ,@body))
(mac tr        body `(tag tr ,@body))

(flet1 pratoms (body)
    ;; If there are any atoms or constants (quote), evaluate
    ;; everything and print everything. Otherwise just evaluate them
    ;; all as code without explicitly printing everything..
    (if (or (no body)
            (all [and (consp _) (no (is (car _) 'quote))]
                 body))
        body
        `((pr ,@body)))
  (mac td      body         `(tag td ,@(pratoms body)))
  (mac trtd    body         `(tr (td ,@(pratoms body))))
  (mac tdr     body         `(tag (td align 'right) ,@(pratoms body)))
  (mac tdcolor (col . body) `(tag (td bgcolor ,col) ,@(pratoms body))))

(mac row args
  "Creates a row of a table with the given data."
  `(tr ,@(map [list 'td _] args)))

(mac prrow args
  "Prints a table row. If an argument is a number, it is right 
   aligned."
  (w/uniq g
    `(tr ,@(mapeach a args
             `(let ,g ,a
                (if (numberp ,g)
                    (tdr (pr ,g))
                    (td  (pr ,g))))))))

(mac prbold body
  "Prints the body and surrounds it with bold tags."
  `(tag b (pr ,@body)))

(def para args
  "Prints a paragraph tag followed by the rest of the args."
  (gentag p)
  (when args (apply #'pr args)))

(def menu (name items ? sel)
  "Prints a menu with the given name and items."
  (tag (select name name)
    (each i items
      (tag (option selected (is i sel))
        (pr i)))))

(mac whitepage body
  "Creates a basic white page."
  `(tag html
     (tag (body bgcolor white* alink linkblue*)
       ,@body)))

(def errpage args
  "Prints an error page with the arguments."
  (whitepage (apply #'prn args)))

(def blank-url ()
  "Returns the url of a blank gif."
  "s.gif")

;; The name "space" cannot be used because it is a symbol for the
;; optimization settings in the common-lisp package.
(def spacer (! (h 1) (v 1))
  "Generates HTML for an H by V blank image."
  (gentag img src (blank-url) height h width v))

(def spacerow (h)
  "Prints a spacer row in a table of the given height."
  (pr "<tr style=\"height:" h "px\"></tr>"))

(mac zerotable body
  "Executes BODY and surrounds the output with tags for a table with 
   0 for its border, cellpadding, and cellspacing."
  `(tag (table border 0 cellpadding 0 cellspacing 0)
     ,@body))

(mac sptab body
  "Executes BODY and surrounds the output with tags for a table with
   0 for its border, cellpading, and 7 for cellspacing."
  `(tag (table style "border-spacing: 7px 0px;")
     ,@body))

(mac widtable (w . body)
  "Executes BODY and surrounds the output with tags for a single
   celled table with width W."
  `(tag (table width ,w) (trtd ,@body)))

(def cellpr (x)
  "If X, print it, otherwise print '&nbsp'."
  (pr (or x "&nbsp")))

(def submit (? (val "submit"))
  "Prints the tags for a submit button."
  (gentag input type 'submit value val))

(def but (? (text "submit") (name nil))
  "Prints a tag for a submit button."
  (gentag input type 'submit name name value text))

(def buts (name . texts)
  "Prints tags for buttons with the given name, and one for each text
   in TEXTS."
  (if (no texts)
      (but)
      (do (but (car texts) name)
          (each text (cdr texts)
            (pr " ")
            (but text name)))))

(mac spanrow (n . body)
  "Executes BODY and surrounds the output with a tr tag and a td tag
   with colspan=N."
  `(tr (tag (td colspan ,n) ,@body)))

(mac form (action . body)
  "Executes BODY and surrounds the output with tags for a form with
   the given action."
  `(tag (form method "post" action ,action) ,@body))

(mac textarea (name rows cols . body)
  "Executes BODY and surrounds the output with tags for a textarea
   with the given arguments."
  `(tag (textarea name ,name rows ,rows cols ,cols) ,@body))

(def input (name ? (val "") (size 10))
  "Creates an input tag with the given arguments."
  (gentag input type 'text name name value val size size))

(mac inputs args
  "Creates a table of input tags with the format: name - label - size
   - value. The size can either be an atom or a list containing
   (row col)."
  `(tag (table border 0)
     ,@(map (fn ((name label len text))
              (w/uniq (gl gt)
                `(let ,gl ,len
                   (tr (td  (pr ',label ":"))
                       (if (consp ,gl)
                           (td (textarea ',name (car ,gl) (cadr ,gl)
                                 (iflet ,gt ,text (pr ,gt))))
                           (td (gentag input
                                       type ',(if (is label 'password)
                                                  'password
                                                  'text)
                                       name ',name
                                       size ,gl
                                       value ,text)))))))
            (group args :by 4))))

(def single-input (label name chars btext ? pwd)
  "Prints text followed by a submit button."
  (pr label)
  (gentag input type (if pwd 'password 'text) name name size chars)
  (sp)
  (submit btext))

(mac cdata body
  "Evaluates BODY and surrounds the output in a cdata tag."
  `(do (pr "<![CDATA[")
       ,@body
       (pr "]]>")))

(def eschtml (str)
  "Returns the input string, but with the characters <, >, \", ', and
   & with the html codes."
  (tostring
    (each c str
      (pr (case c #\< "&#60"
                  #\> "&#62"
                  #\& "&#38"
                  t   c)))))

(def nbsp ()
  "Outputs a non-breaking space."
  (pr "&nbsp;"))

(def link (text ? (dest text) color)
  "Prints tags for a link with the given text, destination and 
   color."
  (tag (a href dest)
    (tag-if color (font color color)
      (pr text))))

(def underlink (text ? (dest text))
  "Prints tags for a link and underline the text of the link."
  (tag (a href dest) (tag u (pr text))))

(def striptags (s)
  "Remove all of the tags from the given string."
  (let intag nil
    (tostring
      (each c s
        (if (is c #\<) (= intag t)
            (is c #\>) (= intag nil)
            (no intag) (pr c))))))

(def clean-url (u)
  "Removes all characters that are \", ', <, or >."
  (rem [in _ #\" #\' #\< #\>] u))

(def shortlink (url)
  "Print a link. If URL is longer than seven characters, cut off the
   first seven characters."
  (unless (or (no url) (< (len url) 7))
    (link (cut url 7) url)))

(def parafy (str)
  "Return a string with an opening paragraph tag inserted after every
   blank line."
  (let ink nil
    (tostring
      (each c str
        (pr c)
        (unless (whitec c) (= ink t))
        (when (is c #\newline)
          (unless ink (pr "<p>"))
          (= ink nil))))))

(mac spanclass (name . body)
  "Evaluates BODY, and surrounds the output with span tags."
  `(tag (span class ',name) ,@body))

(def pagemessage (text)
  "Unless text is nil, print it followed by two break tags."
  (when text (prn text) (br2)))

(def valid-url (url)
  "Is this a valid url?"
  (and (len> url 10)
       (or (begins url "http://")
           (begins url "https://"))
       (~find [in _ #\< #\> #\" #\'] url)))

(mac fontcolor (c . body)
  "Evaluates BODY and surrounds the output with tags for the font to
   be C."
  (w/uniq g
    `(iflet ,g ,c
       (tag (font color ,g) ,@body)
       (do ,@body))))
