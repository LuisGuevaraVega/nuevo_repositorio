clear all
set more off

*parámetros
// directorios
global DIR_RAIZ "C:\Users\user\Documents\1 Archivos Paquetes Estadísticos\2022 - 2\Curso_Enaho_INEI"
global DIR_DATOS "$DIR_RAIZ\4_datos"
global DIR_RESUL "$DIR_RAIZ\6_resultados"

// archivos
global DATOS_300 "enaho01a-2022-300.dta"
global DATOS_400 "enaho01a-2022-400.dta"

// log-file
log using "$DIR_RESUL\Repaso parcial.log"

//archivos de datos
cd "$DIR_DATOS"

//verificando si el archivo necesita traducción
unicode analyze $DATOS_300

unicode encoding set ISO-8859-1

unicode translate $DATOS_300
unicode translate $DATOS_400

 //usando data
 use $DATOS_300, clear
 merge 1:1 aÑo mes conglome vivienda hogar codperso using $DATOS_400
 keep if _m==3
 drop _merge
 
 destring codinfor, replace
 keep if codinfor >= 1 & p204 == 1
 
*niveles de análisis

*Geográfico

//área de residencia
gen area = estrato
recode area (1/5=1) (6/8=2)
//etiquetando
lab var area "Area de residencia"
lab def larea 1 "Urbana" 2 "Rural"
lab val area larea

//Ámbito geográfico

gen ambiGeografico = 1 if dominio == 8
replace ambiGeografico = 2 if (dominio >= 1 & dominio <= 7) & (estrato >=1 & estrato <= 5)
replace ambiGeografico = 3 if (dominio >=1 & dominio <=7) & (estrato >=6 & estrato <=8)
//etiquetando
lab var ambiGeografico "Ámbito geográfico"
lab def lambiGeografico 1 "Lima Metropolitana" 2 "Resto Urbano" 3 "Área Rural"
lab val ambiGeografico lambiGeografico

//Región
gen region = substr(ubigeo,1,2)
destring region, replace
//etiquetando
label var region "Región"
label def lregion 1 "Amazonas" 2 "Ancash" 3 "Apurimac" 4 "Arequipa" 5 "Ayacucho"  ///
	6 "Cajamarca" 7 "Callao" 8 "Cusco" 9 "Huancavelica" 10 "Huanuco"  ///
	11 "Ica" 12 "Junin" 13 "La Libertad" 14 "Lambayeque" 15 "Lima"  ///
	16 "Loreto" 17 "Madre de Dios" 18 "Moquegua" 19 "Pasco" 20 "Piura"   ///
	21 "Puno" 22 "San Martín" 23 "Tacna" 24 "Tumbes" 25 "Ucayali"
label val region lregion

*Demográfico

//Sexo
gen sexo = p207
lab var sexo "Sexo"
lab def lsexo 1 "Hombre" 2 "Mujer"
lab val sexo lsexo

//Edad del entrevistado

gen edadEntrev = .
replace edadEntrev = 1 if p208a <= 2
replace edadEntrev = 2 if p208a >= 3 & p208a <= 5
replace edadEntrev = 3 if p208a >= 6 & p208a <= 11
replace edadEntrev = 4 if p208a >= 12 & p208a <= 17
replace edadEntrev = 4 if p208a >=18
//etiquetando
lab var edadEntrev "Edad del Entrevistado"
lab def ledadEntrev 1 "Menos de 2 años" 2 "De 3 a 5 años" 3 "De 6 a 11 años" 4 "De 12 a 17 años" 5 "De 18 a más años"
lab val edadEntrev ledadEntrev

//Lengua Materna

recode p300a (1/3=1) (10/15=1) (4=2) (6/9=3), g (lengMater)
// Etiquetando
lab var lengMater "Lengua Materna"
lab def llengMater 1 "Lengua nativa" 2 "Castellana" 3 "Otros"
lab val lengMater llengMater

*VARIABLES DE ANÁLISIS

//Edad según minedu

destring aÑo, replace
gen edadMinedu=.
replace edadMinedu = aÑo - p400a3 if p400a2 <= 3
replace edadMinedu = aÑo - p400a3 - 1 if p400a2 > 3
lab var edadMinedu "Edad según Minedu"

//Asistencia escolar a educación inicial

gen asisInicial = 0 if edadMinedu >=3 & edadMinedu <= 5
replace asisInicial = 1 if edadMinedu >= 3 & edadMinedu <= 5 & p307 == 1 & p308a == 1
//etiquetando
lab var edadMinedu "Asistencia escolar a educación Inicial"
lab def ledadMinedu 1 "Asiste" 0 "No asiste"
lab val edadMinedu ledadMinedu

//Asistencia escolar a educación primaria

gen asisPrimaria = 0 if edadMinedu >= 6 & edadMinedu <= 11
replace asisPrimaria = 1 if edadMinedu >= 6 & edadMinedu <= 11 & p307 == 1 & (p308a == 2 | p308a == 7)
//etiqutando
label var asisPrimaria "Asistencia escolar a educación primaria"
label def lasisPrimaria 1 "Asiste" 0 "No asiste"
label val asisPrimaria lasisPrimaria

//Asistencia escolar a educación secundaria // Para nivel secundaria, ya no se cuentan los años Minedu, sino los años cumplidos.

gen asisSecundaria = 0 if p208a >= 12 & p208a <= 16
replace asisSecundaria = 1 if p208a >=12 & p208a <= 16 & p306 == 1 & p307 == 1 & p308a == 3
//etiquetando
lab var asisSecundaria "Asistencia Escolar a Educación Secundaria"
lab def lasisSecundaria 1 "Asiste" 0 "No asiste"
lab val asisSecundaria lasisSecundaria

// Uso de internet
gen usoInternet = 1 if p314a == 1
replace usoInternet = 0 if p314a == 2
//etiquetando
lab var usoInternet "Uso de Internet"
lab def lusointernet 1 "Usa" 0 "No usa"
lab val usoInternet lusointernet

*Analizando datos

//diseño muestral
svyset [pw = factor], psu (conglome) strata (estrato) singleunit(centered)

svy: tab asisPrimaria usoInternet, column se cv ci percent

svy: mean asisPrimaria usoInternet
tabstat asisPrimaria usoInternet [aw=factor]
tab asisPrimaria usoInternet [iw=factor]
*Guardando

cd "$DIR_RESUL"

save $DATOS_300_DIT0, replace

log close