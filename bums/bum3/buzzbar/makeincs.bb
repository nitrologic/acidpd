� � (0,"ram:angle.inc")   � 0,?angle,?angle2-?angle   � 0 ��  � � (0,"ram:distance.inc")   � 0,?distance,?distance2-?distance   � 0 ��  �   distance  �� d2,d0:�Q xpos:�� d0:xpos        ;d0=width  �� d3,d1:�Q ypos:�� d1:ypos        ;d1=height  �\ d0,d1:�H kludge                  ;kludge if equal  �O ygtx:�u d0,d1:ygtx               ;d0=greater side  �� d1:�P yne:��:yne                ;if short side 0 len=other  �� d1:�[ d1:�r d0,d1:�}#7,d1    ;look up=short/long  �= d1,d1:�� d0  �r lvals(pc,d1.w),d0:��  kludge:�� #27146,d0:�� d0:�= d1,d0:�� ;multiply by sqrt(2)  lvals:�* "len.inc" distance2  angle   ��#0,d2                                  ;d2=quadrant   �� d1:�Q hpos:��#16,d2:�� d1:hpos     ;y positive   �� d0:�Q wpos:�s#8,d2:�� d0:wpos        ;x positive   �\ d1,d0:�O notsteep:�P neq   �~#$2000,d1:�X flow:neq   �s #4,d2:�u d1,d0:notsteep   �� d1:�P noflow:��#0,d1:�X flow:noflow   �v.ld0:�� d0:�r d1,d0:�}#6,d0:�B#1022,d0   �~ arc(pc,d0),d1   flow:�~.l oct(pc,d2),d0:�s d0,d1:�� d0:�= d1,d0:��   oct:�%.w 0,0,$4000,-1,0,-1,$c000,0       �%.w $8000,-1,$4000,0,$8000,0,$C000,-1   arc:�* "arc.inc" angle2 