� arexxres.bb  ;Sending String files to ARexx. ; ;You will notice a strange occurance!  if we send a string ;file that does not allow a result string to be sent back ;(i.e. no EXIT) then it sends us the result as a command ;message before it returns our original message. ;Try removing the EXIT from the string and you will see ;what I mean. ;Further to that you can crash the rexx task the same way ;it appears to be a bug in arexx and even if this is not ;the case it certainly is not compatible with the ;way this library expects arexx to behave. ;You will also  notice that you loose a small amount of ;memory each time this occurs so if you are going to use ;String Files then make sure there is an EXIT in the ;string somewhere.   ;!!!!!!!!!!!!!!!!!!!!!!!!!!!! ;NOTE THIS IS AN EARLY DEVELOPMENT EXAMPLES AND ;DOES NOT USE CORRECT EVENT LOOPING PROCEDURES. ;SOME ERRORS IN THIS CODE (and comments) HAVE NOW ;BEEN REMOVED AND/OR CORRECTED.   ;DefaultIDCMP $200         ;window will only report CLOSE GADGET � 0 � 0,0,0,350,250,$143f,"TEST FUNCTION0",0,1 � 1,200,0,350,250,$143f,"TEST FUNCTION1",0,1  Port.l = �("FuncPort") msg.l = �(Port,".rexx","FuncPort") � msg,"EXIT ERRORTEXT(10)",#RXCOMM|#RXFF_RESULT|#RXFF_STRING  ;Get the first message Packet to arrive  LABEL:  ��    �  �� � = NULL      ;WE will GURU If we attempt To GetRexxResult from an intuiMessage (not any more!!)  Rmsg.l=�(Port)    ;there is no error checking from here on!!  ݂ ܄(Rmsg)," ",܄(msg)," (MsgPackets Address)"  ݂ ܄(�	(Rmsg,1))," (First Result)"  ݂ ܄(�	(Rmsg,2))," (Second Result)"  ݂ �(Rmsg)," (Result string)"  ݂ �
(Rmsg,1)," (Command String)"  � Rmsg,0,0,"Reply"  ݂ "--------------"  ;Get the second (either from ARexx or because we replied to our original msg above) LABEL1: � Rmsg.l=�(Port) � �(Rmsg)      ݂ ܄(Rmsg)," ",܄(msg)      ݂ ܄(�	(msg,1))      ݂ ܄(�	(msg,2))      ݂ �(msg)      ݂ �
(msg,1)      ݂ "--------------"      ݂ "CLICK MOUSE BUTTON" �� �(Port) �(msg) ��   �                          ;Wait on event from window   ev.l  = �   ݂ ܄(ev)               ;Just to prove all the normal functions   ݂ ܄(�)      ;still work after Wait so long as you call EVENT �� � = 0 �B ev = $200   