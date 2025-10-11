
// Limpiar entorno
clear;
clc;

// Nombre del archivo
filename = "ensayo_n.txt";

// Leer los datos del archivo (todas las filas, 17 columnas)
data = read(filename, -1, 17);

// Extraer columnas de hora, minuto y segundo
horas = data(:, 4);
minutos = data(:, 5);
segundos = data(:, 6);

// Convertir tiempo a segundos y luego a minutos desde el inicio
tiempo_segundos = horas * 3600 + minutos * 60 + segundos;
tiempo_inicio = tiempo_segundos(1);
tiempo_en_minutos = (tiempo_segundos - tiempo_inicio) / 60;

// Extraer columnas a graficar (temperaturas, por ejemplo)
columna10 = data(:, 10);
columna11 = data(:, 11);
columna15 = data(:, 15);

// Graficar las variables frente al tiempo
plot(tiempo_en_minutos, columna10, 'b-', ...
     tiempo_en_minutos, columna11, 'r--', ...
     tiempo_en_minutos, columna15, 'g-');

// Etiquetas y leyenda
xlabel("t (min)", "fontsize", 4);
ylabel("T_s (°C)", "fontsize", 4);

// Entidad gráfica actual
h = gce();
h.legend_location = "in_lower_right";
h.font_size = 4;

// Mostrar rejilla
xgrid();
