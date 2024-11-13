HDBC-ODBC
=========

Repository to track down bug in HDBC-odbc.

Original tests aren't run -- I could not build it because of outdated dependencies, so I replaced them with my sample code, `showCrash.hs`.
Run with
`# stack run runtests --install-ghc --stack-yaml stack-21.yaml`

[Original project can be found here](https://github.com/hdbc/hdbc-odbc)

Results I've got so far
- with GHC 8.x it works fine (Stack LTS snapshots before 17)
- with GHC 9.2.8 and 9.4.8 it fails with errors `SqlError {seState = "[]", seNativeError = -2, seErrorMsg = "bindparameter 1: []"}` or
 `SqlError {seState = "[]", seNativeError = -2, seErrorMsg = "SQLNumResultCols: []"}` (snapshots 19 and 20)
- with more recent GHC it usually raises exception `SqlError {seState = "", seNativeError = -1, seErrorMsg = "Tried to use a disposed ODBC Statement handle"}`. If catch this exception, there is another one, `"Tried to use a disposed ODBC Connection handle"`. I've got few crashes on Windows, but with no stack dumps to analyze.

Also, when tracing enabled, last records before "exceptional call" usually looks like this, there is not only possible memory corruption, but a race, too.
```
ffinis
hF
re
efienxge csuttaetreamwe:n t" IwNiStEhR Th aInNdTlOe  m0axi0n0.0T0e0s0t0T0a0bflbea d(cF610,
 F
2S)Q LVCAaLnUcEeSl ((0'x00'0,0 000)0,0 0(0'f1b'a,d c16)0,)  (r'e2t'u,r n2e)d,  0(
'3
'S,Q L3C)l,o s(e'C4u'r,s o4r)(,0 x(0'050'0,0 050)0,0 f b(a'd6c'6,0 )6 )r,e t(u'r7n'e,d  7-)1,
 (
'S8Q'L,F r8e)e,H a(n'd9l'e,( 39,) ;0"x
00
0R0e0q0u0e0s0tfebda dac 6S0T)M Tr ehtaunrdnleed  f0r
om
 Far edeiisnpgo ssetda twermaepnpte rw.i tThh rhoawnidnlge.
```

```
fexecuteraw: "INS
EFRrTe eIiNnTgO  smtaaitne.mTeenstt Twaibtlhe  h(aFn1d,l eF 20)x 0V0A0L0U0E0S0 0(3'108'e,2 c06)0,
 (
'S1Q'L,C a1n)c,e l(('02x'0,0 020)0,0 0(0'331'8,e 23c)6,0 )( 'r4e't,u r4n)e,d  (0'
5'
,S Q5L)C,l o s(e'C6u'r,s o6r)(,0 x(0'070'0,0 070)0,3 1(8'e82'c,6 08)) ,r e(t'u9r'n,e d9 )-;1"



SRQeLqFureesetHeadn dal eS(T3M,T  0hxa0n0d0l0e0 0f0r0o3m1 8ae 2dci6s0p)o sreedt uwrrnaepdp e0r
.
TFhrreoewiinngg .s
truntests: SqlError {seState = "", seNativeError = -1, seErrorMsg = "Tried to use a disposed ODBC Statement handle"}
atement with handle 0x00000000318e7b20
```

I could reproduce this behavior on several system/database/driver combinations:
1. Windows 10/SQL Server 2017/SQl Server Native Client 11 (two different machines)
2. Windows 10/SQL Server 2017/ODBC Driver 17 for SQl Server (two different machines)
3. Windows 10/SQLite (bundled with system)/ODBC Driver for SQLite [from here](http://www.ch-werner.de/sqliteodbc/)
4. Gentoo Linux/MariaDB 10.6/Maria DB Connector ODBC 3.1.8
5. Gentoo Linux/SQLite 3.46.1/ODBC Driver for SQLite
