�� � s.l(2096),c.l(2096)  � i=0 � 2096   c(i)=�(1023*(�((2*��*i)/1024)))   s(i)=�(1023*(�
((2*��*i)/1024))) �  � i=0 � 15:� i,320,256,2:� �4 � 0,44,320,256,$fff8,2,8,4,320,320 ��   �   � 1,�(16),�(16),�(16)   � 2,�(16),�(16),�(16)   � 3,�(16),�(16),�(16)   rv=�*0.3+0.05   gv=�*0.3+0.05   bv=�*0.3+0.05   rc=8:gc=8:bc=8:cc=1:ccc=1   ibxarg1=�(�(1023)):ibxarg2=�(�(1023)):ibyarg1=�(�(1023)):ibyarg2=�(�(1023))   xr1=�(�(40)-20):xr2=�(�(40)-20):yr1=�(�(40)-20):yr2=�(�(40)-20)   xinc1=25-�(50):xinc2=25-�(50)   yinc1=25-�(50):yinc2=25-�(50)   arginc1=(�(9)-4)*8   arginc2=(�(9)-4)*8   arginc3=(�(9)-4)*8   arginc4=(�(9)-4)*8   �   � j=0 � 14   cc=0:ccc=1   ibxarg1=�(ibxarg1+xinc1,0,1024)   ibxarg2=�(ibxarg2+xinc2,0,1024)   ibyarg1=�(ibxarg1+yinc1,0,1024)   ibyarg2=�(ibxarg2+yinc2,0,1024)   bxarg1=ibxarg1:bxarg2=ibxarg2:byarg1=ibxarg1:byarg2=ibyarg2   �, � j:�7:� j     � 0     � r=1024 � 192 � -32       cc=�(cc+1,0,4)       � cc=0:ccc=�(ccc+1,1,4):��       bxarg1+xr1:bxarg2+xr2:byarg1+yr1:byarg2+yr2       xarg1=bxarg1:xarg2=bxarg2:yarg1=byarg1:yarg2=byarg2       � i=0 � 1032 � 8         xarg1+arginc1:xarg2+arginc2:yarg1+arginc3:yarg2+arginc4         � calc         � x.l,y.l,ccc         lastx=x:lasty=y       �     �   �   ��     � si=0 � 15         � �(0)>0           � �(0)=1:�� �:�� ��:� l1:��           � �(0)=>1:�� �:�� ��:� l2:��         ��         ibxarg1=�(ibxarg1+xinc1,0,1024)         ibxarg2=�(ibxarg2+xinc2,0,1024)         ibyarg1=�(ibxarg1+yinc1,0,1024)         ibyarg2=�(ibxarg2+yinc2,0,1024)         bxarg1=ibxarg1:bxarg2=ibxarg2:byarg1=ibxarg1:byarg2=ibyarg2       �, � (si+15) �� 16:� 0       bi=si:r=1056:cc=0:ccc=1       � kk=0 � 14         cc=�(cc+1,0,4)         � cc=0:ccc=�(ccc+1,1,4):��         r-32         bxarg1+xr1:bxarg2+xr2:byarg1+yr1:byarg2+yr2         xarg1=bxarg1:xarg2=bxarg2:yarg1=byarg1:yarg2=byarg2         � i=0 � 1032 � 8           xarg1+arginc1:xarg2+arginc2:yarg1+arginc3:yarg2+arginc4           � calc           � x.l,y.l,ccc           lastx=x:lasty=y         �         �7         � bi         bi=�(bi+1,0,16)       �       bi=(si+13) �� 16       � kk=0 � 11         cc=�(cc+1,0,4)         � cc=0:ccc=�(ccc+1,1,4):��         r-32         bxarg1+xr1:bxarg2+xr2:byarg1+yr1:byarg2+yr2         xarg1=bxarg1:xarg2=bxarg2:yarg1=byarg1:yarg2=byarg2         � i=0 � 1032 � 8           xarg1+arginc1:xarg2+arginc2:yarg1+arginc3:yarg2+arginc4           � calc           � x,y,ccc           lastx=x:lasty=y         �         �7         � bi         bi=�(bi+15,0,16)       �     �   �� l1:�� l2:�5:�7 50 �  calc:   xarg1=�(xarg1,0,1024)   xarg2=�(xarg2,0,1024)   yarg1=�(yarg1,0,1024)   yarg2=�(yarg2,0,1024)   x1.l=159*c(xarg1):x1=(x1 �E 10)   x2.l=159*c(xarg2):x2=(x2 �E 10)   y1.l=63*s(yarg1):y1=(y1 �E 10)   y2.l=63*s(yarg2):y2=(y2 �E 10)   x.l=x1+x2:x*r:x=x �E 11:x+160   y.l=y1+y2:y*r:y=y �E 10:y+128 �   