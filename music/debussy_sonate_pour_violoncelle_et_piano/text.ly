prologueTempo = \markup {\large\bold "Lent (" 48 � 54 \large\bold "="
%  \note #2 #0 #1
  \note #"4" #1
  \large\bold ")"
  Sostenuto e molto resoluto
}

raisePrologueTempo = \markup {
  \raise #5 \prologueTempo
}

cedez = \markup {
  \large\bold "C�dez"
}

raiseCedez = \markup {
  \large\bold \raise #2 "C�dez"
}

pocoAnimando = \markup {
  \large\bold "Poco animando"
}

auMouvt = \markup {
  \large\bold "au Mouv"
  \raise #0.5 t
}
