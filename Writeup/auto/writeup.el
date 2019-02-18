(TeX-add-style-hook
 "writeup"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("paper" "12pt")))
   (TeX-run-style-hooks
    "latex2e"
    "paper"
    "paper12"
    "Schwieg"))
 :latex)

