## Scrapper Chronologického registra Slov-Lex ##
Scraper parsuje zoznamy legislatívnych predpisov SR dostupných na https://www.slov-lex.sk/pravne-predpisy
Vytvorí z nich HASH a následne umožní vypísanie vo forme CSV.

### Interné dátové štruktúry ###
```
%x->{$rok}->{lexs}=>[
                  {
                  index=>"číslo_predpisu/rok",
                  type=>"typ predpisu",
                  fullname=>"plný názov predpisu",
                  uri=>"Slov-Lex URI predpisu"
                  }]
```

### Príklad výstupu ###
```
:~/slov-lex$ perl scrap.pl
Processing: 2023. Done
1/2023%Zákon%Zákon, ktorým sa mení a dopĺňa zákon č. 311/2001 Z. z. Zákonník práce v znení neskorších predpisov%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/1/
2/2023%Zákon%Zákon, ktorým sa mení a dopĺňa zákon č. 220/2004 Z. z. o ochrane a využívaní poľnohospodárskej pôdy a o zmene zákona č. 245/2003 Z. z. o integrovanej prevencii a kontrole znečisťovania životného prostredia a o zmene a doplnení niektorých zákonov v znení neskorších predpisov a ktorým sa menia a dopĺňajú niektoré zákony%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/2/
3/2023%Nariadenie%Nariadenie vlády Slovenskej republiky, ktorým sa ustanovujú pravidlá poskytovania podpory na neprojektové opatrenia Strategického plánu spoločnej poľnohospodárskej politiky%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/3/
4/2023%Nariadenie%Nariadenie vlády Slovenskej republiky, ktorým sa mení a dopĺňa nariadenie vlády Slovenskej republiky č. 50/2007 Z. z. o registrácii odrôd pestovaných rastlín v znení neskorších predpisov%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/4/
5/2023%Nariadenie%Nariadenie vlády Slovenskej republiky, ktorým sa mení a dopĺňa nariadenie vlády Slovenskej republiky č. 195/2018 Z. z., ktorým sa ustanovujú podmienky na poskytnutie investičnej pomoci, maximálna intenzita investičnej pomoci a maximálna výška investičnej pomoci v regiónoch Slovenskej republiky v znení neskorších predpisov%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/5/
6/2023%Zákon%Zákon, ktorým sa mení a dopĺňa zákon č. 7/2005 Z. z. o konkurze a reštrukturalizácii a o zmene a doplnení niektorých zákonov v znení neskorších predpisov%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/6/
7/2023%Nariadenie%Nariadenie vlády Slovenskej republiky o výške pracovnej odmeny a podmienkach jej poskytovania odsúdeným%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/7/
8/2023%Zákon%Zákon, ktorým sa mení a dopĺňa zákon č. 513/1991 Zb. Obchodný zákonník v znení neskorších predpisov a ktorým sa menia a dopĺňajú niektoré zákony%https://www.slov-lex.sk/pravne-predpisy/SK/ZZ/2023/8/
```
