import json,pathlib,re
root=pathlib.Path(__file__).resolve().parents[1]
ar=json.loads((root/'assets/raw/closing-ar.json').read_text(encoding='utf-8'))
ar=[re.sub(r'\(adsbygoogle.*?push\(\{\}\);','',x,flags=re.S) for x in ar]
ar=[' '.join(x.split()) for x in ar]
tr=[
"Allâhümme rabbenâ, hallisnâ ve ecirnâ ve neccinâ mine’n-nâr. Ve âfinâ va’fü annâ ve edhilne’l-cennete dâra kudsike mea’l-ebrâr. Bi-afvike yâ Mücîr, bi-fadlike yâ Gaffâr. Ve es’elüke bi-hakkı hâzihi’l-esmâi’l-kerîmeti’ş-şerîfeti ve’s-sıfâti’l-celîleti’l-latîfeti en tüsalliye alâ seyyidinâ Muhammedin ve alâ âlihî ve sahbihî bi-adedi hasenâti Muhammedin. Bismillâh.",
"Hasbiyallâh. Lâ ilâhe illallâh. Şehidallâh. Kul hüvallâh. Mâ şâallâh. Rabbiyallâh. Tebârakellâh. Teâlallâh. Tevekkeltü alallâh. Feseyekfîkehümullâh ve hüve’s-semîu’l-alîm. Sübhâneke yâ lâ ilâhe illâ ente’l-emânü’l-emân. Lâ uhsî senâen aleyke ente kemâ esneyte alâ nefsik. Yâ Allâh, yâ Rahmân, yâ Rahîm, yâ Gafûr, yâ Şekûr.",
"Es’elüke bimâ ahsaytehû aleyke min esmâike’l-hüsnâ ve sıfâtike’l-ulyâ ve kelimâtike’t-tâmmeti en tağfira lî ve li-vâlideyye ve li-üstâzî Saîdi’n-Nûrsî ve li-talebeti resâili’n-nûri ve li-cemîi’l-mü’minîne ve’l-mü’minâti ve’l-müslimîne ve’l-müslimâti’l-ahyâi minhüm ve’l-emvât. Ve terhamenâ rahmeten tüğnînâ bihâ an rahmeti men sivâke min halkıke ve en takdıye havâicenâ ve tu’tiyenâ süâlenâ fi’d-dünyâ ve’l-âhirati ve tahtime lenâ bi’s-seâdeti ve’ş-şehâdeti ve’l-kerâmeti ve’l-büşrâ inde firâki’d-dünyâ ve tecziye Muhammeden sallallâhü aleyhi ve selleme annâ mâ hüve ehlühû ve müstehakkuh.",
"Ve en lâ tekilenâ alâ enfüsinâ tarfete aynin ve lâ ilâ ehadin min halkık. Ve tusliha lenâ şe’nenâ ve en tahrusenâ bi-aynike’lletî lâ tenâmü ve tahfezanâ bi-rüknike’llezî lâ yürâmü yâ ze’l-celâli ve’l-ikrâm. Ve en tasrife annâ ve ammen ullika aleyhi hâzihi’l-esmâü âfete’l-cinni ve’l-insi ve’ş-şeyâtîn.",
"Ve zelzelete’l-ardı ve dekdekete’l-cibâli min haşyetih. Ve âfete’t-tâûni ve’l-vebâi ve ayne’s-sûi ve vecea’l-cevârihi ve sâira’l-âfât. Ve tahfezanâ min külli şerrin ve sû’. Ve terzükanâ’s-selâmete ve’l-âfiyete ve’l-hayra fi’d-dünyâ ve’l-âhirati bi-rahmetike yâ erhame’r-râhimîn. Ve sallallâhü alâ seyyidinâ Muhammedin ve âlihî ve sahbihî ecmaîn. Ve’l-hamdü lillâhi Rabbi’l-âlemîn."
]
meal=[
"Allah’ım, Rabbimiz! Bizi ateşten kurtar, koru ve esenliğe çıkar. Bize afiyet ver, bizi affet ve iyi kullarınla birlikte kutsal yurdun olan cennete koy. Ey koruyucu, affınla; ey çok bağışlayan, lütfunla! Bu değerli ve şerefli isimlerin, yüce ve ince sıfatların hakkı için senden, Efendimiz Muhammed’e, ailesine ve arkadaşlarına onun iyilikleri sayısınca salât etmeni istiyorum. Allah’ın adıyla.",
"Allah bana yeter. Allah’tan başka ilah yoktur. Allah şahitlik eder. De ki: O Allah’tır. Allah’ın dilediği olur. Rabbim Allah’tır. Allah’ın bereketi ve yüceliği sonsuzdur. Allah’a dayandım. Onlara karşı Allah sana yetecektir; o işiten ve bilendir. Seni eksikliklerden uzak tutarım. Senden başka ilah yoktur; güven diliyoruz. Sana övgülerimi sayıp bitiremem; sen kendini övdüğün gibisin. Ey Allah, ey Rahmân, ey Rahîm, ey çok bağışlayan, ey şükre bol karşılık veren!",
"Kendin için saydığın en güzel isimlerin, yüce sıfatların ve eksiksiz sözlerinle senden, beni, annemi ve babamı, üstadım Said Nursî’yi, Risale-i Nur talebelerini ve yaşayan ya da ölmüş bütün erkek ve kadın müminleri ve Müslümanları bağışlamanı istiyorum. Bize, yarattıklarından başkasının merhametine ihtiyaç bırakmayacak bir merhamet ver. Dünya ve ahirette ihtiyaçlarımızı karşıla, dileklerimizi ver. Dünyadan ayrılırken sonumuzu mutluluk, şehadet, ikram ve müjdeyle tamamla. Muhammed’e, Allah’ın salât ve selamı onun üzerine olsun, bizim adımıza layık olduğu karşılığı ver.",
"Bizi bir göz kırpması kadar bile kendimize veya yarattıklarından birine bırakma. İşimizi düzelt. Ey yücelik ve ikram sahibi, bizi uyumayan gözetiminle koru, sarsılmaz dayanağınla muhafaza et. Bizden ve bu isimleri üzerinde taşıyandan cinlerin, insanların ve şeytanların zararını uzaklaştır.",
"Yer sarsıntısını, korkusuyla dağların parçalanmasını, tâun ve salgın hastalıklarını, kötü gözü, organların ağrısını ve diğer felaketleri bizden uzaklaştır. Bizi her türlü kötülük ve zarardan koru. Ey merhametlilerin en merhametlisi, rahmetinle dünya ve ahirette bize esenlik, afiyet ve hayır ver. Allah’ın salâtı Efendimiz Muhammed’in, ailesinin ve bütün arkadaşlarının üzerine olsun. Hamd âlemlerin Rabbi Allah’adır."
]
b={'number':101,'title':'Cevşen Duası','source':'https://www.nukteler.com/cevsen-hatim-duasi/','pronunciationSource':'https://www.muhammed.net/2023/01/cevsen-ul-kebir-duasi-okunusu-fazileti.html','mealSource':'Arapça dua metninden bu uygulama için hazırlanmış sade Türkçe anlam aktarımı.','rows':[dict(ar=a,tr=t,meal=m) for a,t,m in zip(ar,tr,meal)]}
chapters=json.loads((root/'assets/cevsen.json').read_text(encoding='utf-8'))[:100];chapters.append(b)
(root/'assets/cevsen.json').write_text(json.dumps(chapters,ensure_ascii=False,indent=2),encoding='utf-8')
s=(root/'assets/raw/audio-dua.html').read_text(encoding='utf-8-sig')
d=json.loads(re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',s)[1])['props']['pageProps']
print('Closing audio:', d.get('audioUrl'), d.get('durationMs'))
clip={'bab':101,'file':'dua.mp3','startMs':0,'endMs':d['durationMs'],'source':d['audioUrl']}
audio=json.loads((root/'assets/audio/chapters.json').read_text())[:100];audio.append(clip)
(root/'assets/audio/chapters.json').write_text(json.dumps(audio,indent=2))
