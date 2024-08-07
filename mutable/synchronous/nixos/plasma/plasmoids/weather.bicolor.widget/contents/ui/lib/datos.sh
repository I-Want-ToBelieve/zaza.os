#!/bin/bash

# Obteniendo las coordenadas geográficas
cordeprev3=$(curl -s ipinfo.io)
cordeprev2=$(echo "$cordeprev3" | grep "loc")
textno=$(echo "$cordeprev3" | grep "textoquenoesta")

if [[ "$cordeprev2" = "$textno" ]]; then
    contenidoIpBase=$(curl -s https://api.ipbase.com/v1/json/)
    contenidoIpBaseAjs=$(echo "$contenidoIpBase" | sed 's/,/\n/g')

    findLatitude=$(echo "$contenidoIpBaseAjs" | grep "latitude")
    findLatitude01=$(echo "$findLatitude" | sed 's/"latitude"://g')
    if [[ "$findLatitude01" = "$textno" ]]; then
         contenidoIpBase02=$(curl -s http://ip-api.com/json/?fields=lat,lon)
         contenidoIpBase02Ajs=$(echo "$contenidoIpBase02" | sed 's/,/\n/g')
         findLatitude02=$(echo "$contenidoIpBase02Ajs" | grep "lat")
         findLatitude03=$(echo "$findLatitude02" | sed 's/"lat"://g')
         latitude=$(echo "$findLatitude01" | sed 's/,//g')

         findLongitud=$(echo "$contenidoIpBase02Ajs" | grep "lon")
         findLongitud01=$(echo "$findLongitud" | sed 's/"lon"://g')
         longitud=$(echo "$findLongitud01" | sed 's/,//g')
         else
         latitude=$(echo "$findLatitude01" | sed 's/,//g')
         findLongitud=$(echo "$contenidoIpBaseAjs" | grep "longitude")
         findLongitud01=$(echo "$findLongitud" | sed 's/"longitude"://g')
         longitud=$(echo "$findLongitud01" | sed 's/,//g')
     fi
else
    cordeprev1=$(echo "$cordeprev2" | sed 's/"loc": "//g')
    cordeprev0=$(echo "$cordeprev1" | sed 's/",//g')
    cordeprev=$(echo "$cordeprev1" | sed 's/,/\n/g')
    latitudeprev=$(echo "$cordeprev" | head -n 1)
    latitude=$(echo "$latitudeprev" | sed 's/ //g')

    longitudprev=$(echo "$cordeprev" | sed -n '2p')
    longitud=$(echo "$longitudprev" | sed 's/"//g')
fi

# Validación de entradas nulas
if [ $1 = "null" ]
  then latitudefinal=$latitude
  else latitudefinal=$1
  fi
if [ $2 = "null" ]
   then longitudfinal=$longitud
   else longitudfinal=$2
   fi

corde="latitude=$latitudefinal&longitude=$longitudfinal"

# URL de la API meteorológica
apiurl="https://api.open-meteo.com/v1/forecast?$corde&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"

# Descargar datos JSON desde la API
full=$(curl -s "$apiurl")
fulfilt=$(echo "$full" | sed 's/,/,\n/g')
fullfinal03=$(echo "$fulfilt" | sed 's/"temperature_2m":"°C",//g')
fullfinal02=$(echo "$fullfinal03" | sed 's/"temperature_2m_max"//g')
fullfinal=$(echo "$fullfinal02" | sed 's/"temperature_2m_min"//g')
temprev=$(echo "$fullfinal" | grep "temperature_2m")
temprevfirst=$(echo "$temprev" | sed 's/"temperature_2m"://g')
tem=$(echo "$temprevfirst" | sed 's/,//g')

# opteniendo temperatura minima
mintemp03=$(echo "$fulfilt" | sed 's/"temperature_2m_min":"°C"},//g')
mintemp02=$(echo "$mintemp03" | grep "temperature_2m_min")
mintemp01=$(echo "$mintemp02" | sed 's/"temperature_2m_min"//g')
mintemp=$(echo "$mintemp01" | grep -oE '[0-9]+([.][0-9]+)?' )

# opteniendo temperatura maxima
maxtemp03=$(echo "$fulfilt" | sed 's/"temperature_2m_max":"°C"},//g')
maxtemp02=$(echo "$maxtemp03" | grep "temperature_2m_max")
maxtemp01=$(echo "$maxtemp02" | sed 's/"temperature_2m_max"//g')
maxtemp=$(echo "$maxtemp01" | grep -oE '[0-9]+([.][0-9]+)?' )

# Código de estado del tiempo
fulltamefinal=$(echo "$fulfilt" | sed 's/"weather_code":"wmo code"//g')
codetemprev=$(echo "$fulltamefinal" | grep "weather_code")
codetemprev1=$(echo "$codetemprev" | sed 's/"weather_code"://g')
codetem=$(echo "$codetemprev1" | grep -oE '[0-9]+([.][0-9]+)?' )

# Establecimiento de la ubicación
getJason=$(curl -s "https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitudefinal&lon=$longitudfinal&accept-language=$4")
textoFinal=$(echo "$getJason" | sed 's/,/,\'$'\n''/g')
city=$(echo "$textoFinal" | grep -o '"city":"[^"]*"' | sed 's/"city":"//;s/"//')
citycond=$(echo "$textoFinal" | grep "textoqueobviamentenoesta")
if [ "$city" = "$citycond" ]; then
        city_distri=$(echo "$textoFinal" | grep -o '"city_district":"[^"]*"' | sed 's/"city_district":"//;s/"//')
        if [ "$city_distri" = "$citycond" ]; then
             state=$(echo "$textoFinal" | grep -o '"state":"[^"]*"' | sed 's/"state":"//;s/"//')
             cityR=$state
       else
             cityR=$city_distri
       fi
    else
        cityR=$city
    fi

# Selección del resultado según el tercer argumento
if [ "$3" = "tem" ]; then
    result=$tem
elif [ "$3" = "codetem" ]; then
    result=$codetem
elif [ "$3" = "ubi" ]; then
    result=$cityR
elif [ "$3" = "min" ]; then
    result=$mintemp
elif [ "$3" = "max" ]; then
    result=$maxtemp
else
    result="null"
fi

echo "$result"
