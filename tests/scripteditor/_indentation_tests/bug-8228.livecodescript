if (gDatf[tPost,i] <> "") and \
      (((gPoly[tPost] = "") and (gSurf[tPost] = gSurg[tPost,i])) or ((gPoly[tPost] <> "") and (gPoly[tPost] = gPolz[tPost,i]))) and \
      (gFra1[tPost,i] <> "") and (gFra2[tPost,i] <> "") and \
      ((gPos2[tPost,i] <> "") or (quote is in gPos2[tPost,i])) and ((gPos3[tPost,i] <> "") or (quote is in gPos3[tPost,i])) and ((gPos4[tPost,i] <> "") or (quote is in gPos4[tPost,i])) and ((gPos5[tPost,i] <> "") or (quote is in gPos5[tPost,i])) and \
      (abs(gDist[tPost]) - abs(gDisu[tPost,i]) <= 0) and \ -- (abs(abs(gDist[tPost]) - abs(gDisu[tPost,i])) <= 440)
      (gBea5[tPost,i] <= 2.0) then
   put tab & gDatf[tPost,i] & tab & gPos2[tPost,i] & gPos3[tPost,i] & gPos4[tPost,i] & gPos5[tPost,i] & tab & gSco1[tPost,i] & tab & gSco2[tPost,i] & tab & gSco3[tPost,i] & tab & gOdds[tPost] & return after fld "Indey"
end if
