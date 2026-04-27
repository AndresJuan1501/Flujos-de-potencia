% Construccion de la matriz Ybarra
% Genera la Ybarra para la subárea "Valle 1" (Entrega 1, item f).
% Autores:     Andres Juan Ortiz Jaimes, Luis Ernesto Jurado Ortiz
% Codigos:     2192124, 2192127
% Fecha:     [05/11/2025]

% Este script:
% 1. Lee los datos de Líneas, Transformadores y Shunts desde Excel.
% 2. Usa Sbase = 150 MVA para todo el sitema y las tensiones base correspondientes de cada linea.
% 3. Modela los transformadores con tap (magnitud) y desfase (grupo).

%% INICIALIZACIÓN Y DEFINICIONES DE BASE

clc
clear
close all
format longG % Formato de números más limpio

disp('Iniciando la construcción de la Ybarra para el área Valle 1...');

% Definiciones del Sistema
Sbase = 150; % Potencia Base del Sistema (MVA) 
N_barras = 25; % número TOTAL de barras en el sistema "Valle 1"

% Creación del Vector de Tensiones Base (Vbase) y matriz de (Ybarra)
Vbase_bus = zeros(N_barras, 1); % Se inicia como un vector de ceros (NxN) para construir Vbases del sistema

% Se asigna el Vbase (kV) a cada bus o barra según el diagrama 'Valle.pdf', teniendo N_barras de elemento
Vbase_bus(1) = 230;
Vbase_bus(2) = 230;
Vbase_bus(3) = 230;
Vbase_bus(4) = 115;
Vbase_bus(5) = 115;
Vbase_bus(6) = 115;
Vbase_bus(7) = 115;
Vbase_bus(8) = 115;
Vbase_bus(9) = 115;
Vbase_bus(10) = 115;
Vbase_bus(11) = 115;
Vbase_bus(12) = 115;
Vbase_bus(13) = 115;
Vbase_bus(14) = 230;
Vbase_bus(15) = 115;
Vbase_bus(16) = 115;
Vbase_bus(17) = 115;
Vbase_bus(18) = 115;
Vbase_bus(19) = 230;
Vbase_bus(20) = 115;
Vbase_bus(21) = 115;
Vbase_bus(22) = 115;
Vbase_bus(23) = 115;
Vbase_bus(24) = 115;
Vbase_bus(25) = 230;

Ybarra = zeros(N_barras, N_barras); % Se inicia como una matriz de ceros (NxN) para construir Ybarra
disp(['Sistema de ' num2str(N_barras) ' barras, Sbase = ' num2str(Sbase) ' MVA.']);
disp('----------------------------------------------------');


%% 1. MODELADO LÍNEAS DE TRANSMISIÓN (Modelo PI Y Modelo linea corta) 

shunt_modelo = input('Ingrese (1) si quiere elementos shunt del Modelo PI de lo contrario digite (0 o otro número diferente de 1): ');  % Pedir con o sin Shunt de las lineas 

disp('Agregando LÍNEAS de transmisión...');
T_lineas = readtable('PARATEC_Líneas_22-10-2025.xlsx'); % Se extrae informacion del excel

for i = 1:height(T_lineas)
        bus_i = T_lineas.barra_i(i);          % Columna 'i' (desde)
        bus_j = T_lineas.barra_j(i);          % Columna 'j' (hasta)
        R_ohm_km = T_lineas.R_km(i);          % Columna 'R (ohm/km)'
        X_ohm_km = T_lineas.X_km(i);          % Columna 'XL (ohm/km)'
        B_uS_km  = T_lineas.B_uS_km(i);       % Columna 'Bc (uS/km)' micro-Siemens
        L_km     = T_lineas.Longitud_km(i);   % Columna 'LONGITUD (km)'

        % 1. Calcular valores totales de cada linea extraida del excel (Ohm y Siemens)
        z_actual_serie = (R_ohm_km + 1j * X_ohm_km) * L_km;
        y_actual_shunt_total = 1j * (B_uS_km * 1e-6) * L_km;
        
        % 2. Calcular Bases en cada iteración (Zbase y Ybase)
        Vbase = Vbase_bus(bus_i); % Vbase (kV) de la línea (barra_i)
        Zbase = (Vbase^2) / Sbase; 
        Ybase = 1 / Zbase; 
        
        % 3. Convertir a P.U. en cada iteración
        z_pu_serie = z_actual_serie / Zbase;
        y_pu_shunt_total = y_actual_shunt_total / Ybase;
        
        % 4. Obtener admitancias para el modelo PI
        y_pu_serie = 1 / z_pu_serie;            % Y de serie
        y_pu_shunt_lado = y_pu_shunt_total / 2; % Y de mitad en cada extremo
        
        % 5. Ensamblar en Ybarra la admitancia calculada de cada iteración
        if (L_km >= 80) && (1 == shunt_modelo)
            Ybarra(bus_i, bus_i) = Ybarra(bus_i, bus_i) + y_pu_serie + y_pu_shunt_lado;
            Ybarra(bus_j, bus_j) = Ybarra(bus_j, bus_j) + y_pu_serie + y_pu_shunt_lado;          
        else 
            Ybarra(bus_i, bus_i) = Ybarra(bus_i, bus_i) + y_pu_serie;
            Ybarra(bus_j, bus_j) = Ybarra(bus_j, bus_j) + y_pu_serie;
        end
            Ybarra(bus_i, bus_j) = Ybarra(bus_i, bus_j) - y_pu_serie;
            Ybarra(bus_j, bus_i) = Ybarra(bus_j, bus_i) - y_pu_serie;
end

disp(['> ' num2str(height(T_lineas)) ' líneas agregadas.']);


%% 2. PROCESAMIENTO DE TRANSFORMADORES (Modelo Tap y Desfase) y resuelve del f.(b) Todos los transformadores están en su tap máximo, mínimo y nominal.

valid_scenarios = {'nominal', 'max', 'min'};
tap_escenario = ''; % creo variable
Validacion = false; % controla la ruptura del bucle

% Bucle para forzar una entrada válida
while ~Validacion

    escenario = input('Ingrese el escenario que desea simular, en su tap "nominal"(1), "máximo"(2), "mínimo"(3) o "mitigación"(4): ', 's');  % Pedir la entrada como texto ('s') adicionalmente

    switch lower(strtrim(escenario))% Usar strtrim para eliminar cualquier espacio en blanco al inicio o final y convertir a minúsculas para un control robusto
        case {'1', 'nominal'}
            tap_escenario = 'nominal'; % reasigno valor de la variable
            Validacion = true; % % rompe el bucle
        case {'2', 'max', 'maximo'}
            tap_escenario = 'max'; % reasigno valor de la variable
            Validacion = true; % % rompe el bucle
        case {'3', 'min', 'minimo'}
            tap_escenario = 'min'; % reasigno valor de la variable
            Validacion = true; % rompe el bucle
         case {'4', 'mitigacion', 'mitigación'}
            tap_escenario = 'nominal'; % Se usa tap nominal como base para la mitigación
            Validacion = true;
        otherwise
            disp('------ERROR: Entrada no válida. Por favor, intente de nuevo.-------');  % Validacion se mantiene en false, el bucle continúa
    end
end

            % --- INICIO CÓDIGO DE MITIGACIÓN (ESCENARIO 4) ---
            % >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            
            disp('APLICANDO OBRAS DE MITIGACIÓN (Escenario 4)...');
            
            % --- OBRA 1: SOLUCIÓN A SOBRECARGA (Línea 19-2) ---
            % El límite térmico (Amperios) se aumenta en 20% para resolver la sobrecarga del 100.98%
            
            idx_19_2 = find((T_lineas.barra_i == 19 & T_lineas.barra_j == 2) | ...
                            (T_lineas.barra_i == 2 & T_lineas.barra_j == 19), 1);
                            
            if ~isempty(idx_19_2)
                limite_antiguo = T_lineas.L_miteT_rmico_A_(idx_19_2);
                % Aumento del 20% en la capacidad térmica
                T_lineas.L_miteT_rmico_A_(idx_19_2) = limite_antiguo * 1.20; 
                disp(['[Obra 1] Capacidad térmica de Línea 19-2 aumentada a: ', num2str(T_lineas.L_miteT_rmico_A_(idx_19_2)), ' A.']);
            else
                warning('Línea 19-2 no encontrada. Verifique el nombre de la columna o los índices de las barras.');
            end



disp(['Simulando con Taps en escenario: ' lower(tap_escenario)]);

% Cálculo del modelo en los transformadores
disp('Agregando TRANSFORMADORES (modelo completo)...');
T_trafos = readtable('PARATEC_Transformadores_22-10-2025.xlsx'); 

Tap_usados_vector = ones(height(T_trafos), 1); % Vector para guardar el tap usado
    
    for k_trafo = 1:height(T_trafos)
        bus_i = T_trafos.barra_i(k_trafo);     % Barra Alta tension 
        bus_j = T_trafos.barra_j(k_trafo);     % Barra Baja tension 
        Z_pu_propio = (T_trafos.Impedancia_Alta_Media_Nom_PS(k_trafo))/100; % Impedancia (R+jX) o Xps en base propia en p.u
        Sbase_trafo = T_trafos.CapacidadNominal_MVA_(k_trafo);  % MVA base del trafo
        Vbase_trafo = T_trafos.Tensi_nNominal_kV_(k_trafo);     % kV base del trafo

        % Datos para Item (d) con Tap y Desfase
        grupo_conexion = T_trafos.GRUPODECONEXI_N(k_trafo);   % Grupo de conexión (0, 1, 11, etc.)
        paso_por_tap_porcentaje = T_trafos.PasoPorTAP___(k_trafo); % Paso por TAP [%]
        paso_por_tap_pu = paso_por_tap_porcentaje / 100; % Paso por TAP en p.u

        % Definición del valor del Tap 't' según el escenario:
        switch lower(tap_escenario) % selecciona y ejecuta segun el caso presentado, lower vuelve los caracteres Mayusculas en minusculas para evitar errores
            case 'nominal'
                t = 1.0; % Tap nominal
            case 'max'  
                t = 1.0 + paso_por_tap_pu*12; % "Paso por TAP p.u" es el incremento del 9 a 21
            case 'min'
                t = 1.0 - paso_por_tap_pu*8; %  "Paso por TAP p.u" es la disminución del paso 9 a 1
            otherwise
                warning('Escenario de tap desconocido. Usando tap nominal (1).');
                t = 1.0;
        end
        
        Tap_usados_vector(k_trafo) = t;
        tap_lado = T_trafos.VoltajePasoNominal_kV_{k_trafo}; % Lado del tap: 'i' o 'j'

        % 1. Recalcular Z_pu a la base del sistema (Sbase = 150 MVA)
        Vbase_sistema = Vbase_bus(bus_i);       % Vbase (kV) de la línea (barra_i)
        Z_pu_nuevo = Z_pu_propio * 1j * (Sbase / Sbase_trafo)*(Vbase_trafo / Vbase_sistema)^2; % la barra donde es 230 algunos transfo la nominal son 220
        
        % 2. Obtener admitancia serie (y_t)
        y_t = 1 / Z_pu_nuevo;
        
        % 3. Calcular Relación de Transformación Compleja (a) si (a = t * e^(j*delta))
        delta_grados = grupo_conexion * (-30); % Desfase del transformador correspondiente: k * -30 grados
        delta_rad = delta_grados * (pi / 180);
        
        a_complex = t * exp(1j * delta_rad);  % a = c si fuese regulante de angulo o magnitud
        a_conjugado = conj(a_complex);        % a* = c* si fuese regulante de angulo o magnitud
        
        % 4. Ensamblar en Ybarra (Modelo de los transformadores con TAP y DESFASE seleccionados)
        % Se verifica en qué lado está el tap, normalmente en el lado de Alta pero hubo 2 transfo que estaban en 115 kV segun el excel por los parametros dados (revisar excel)
        if strcmpi(tap_lado, '220') % Tap en lado i (Primario)
            Ybarra(bus_i, bus_i) = Ybarra(bus_i, bus_i) + (t^2) * y_t;
            Ybarra(bus_j, bus_j) = Ybarra(bus_j, bus_j) + y_t;
            Ybarra(bus_i, bus_j) = Ybarra(bus_i, bus_j) - a_conjugado * y_t;
            Ybarra(bus_j, bus_i) = Ybarra(bus_j, bus_i) - a_complex * y_t;
            
        elseif strcmpi(tap_lado, '115') % Tap en lado j (Secundario)
            Ybarra(bus_i, bus_i) = Ybarra(bus_i, bus_i) + y_t;
            Ybarra(bus_j, bus_j) = Ybarra(bus_j, bus_j) + (t^2) * y_t;
            Ybarra(bus_i, bus_j) = Ybarra(bus_i, bus_j) - a_complex * y_t;
            Ybarra(bus_j, bus_i) = Ybarra(bus_j, bus_i) - a_conjugado * y_t;
        
        else % Default: Asumir tap en lado 'i' si no se especifica
            warning('Lado del tap no especificado para trafo %d-%d. Asumiendo lado i.', bus_i, bus_j);
            Ybarra(bus_i, bus_i) = Ybarra(bus_i, bus_i) + (t^2) * y_t;
            Ybarra(bus_j, bus_j) = Ybarra(bus_j, bus_j) + y_t;
            Ybarra(bus_i, bus_j) = Ybarra(bus_i, bus_j) - a_conjugado * y_t;
            Ybarra(bus_j, bus_i) = Ybarra(bus_j, bus_i) - a_complex * y_t;
        end
    end
    disp(['> ' num2str(height(T_trafos)) ' transformadores agregados.']);
    disp(Ybarra);

%% 3. BLOQUE DE CONSTRUCCIÓN: ANÁLISIS DE CONTINGENCIAS (N-1) y Resuelve del f. (a) la contingencia cuando se saca un elemento (transformador o línea) a la vez.

    disp('INICIANDO ANÁLISIS DE CONTINGENCIA (N-1)');

    % 1. Se toma la Ybarra base (calculada arriba) y se sustrae los elementos para simular una falla (contingencia).
    Ybarra_contingencia = Ybarra; % Copiar la Ybarra base para no modificarla

    % 2. Se pregunta qué elemento sacar
    disp('¿Qué elemento desea sacar de servicio?');
    tipo_contingencia = input('¿Qué elemento desea sacar de servicio? Ingrese el número 1 (Una Línea), 2 (Un Transformador), o 3 (Salir): ');
    
    % 3. Procesar la contingencia
    switch tipo_contingencia
        case 1                      % SACAR UNA LÍNEA (El código busca, recalcula y resta la linea)
            bus_i_falla = input('Ingrese el número de la barra "i" (Desde): ');
            bus_j_falla = input('Ingrese el número de la barra "j" (Hasta): ');
            
            % se busca los índices de la línea (i a j) o (j a i)
            lineas_fuera = find((T_lineas.barra_i == bus_i_falla & T_lineas.barra_j == bus_j_falla) | ...
                              (T_lineas.barra_i == bus_j_falla & T_lineas.barra_j == bus_i_falla));
            
            if isempty(lineas_fuera) % si lineas_fuera esta vacio dar mensaje
                warning('No se encontró ninguna línea entre esos buses.');
            else                 % un for por si hay líneas en paralelo
                for k = 1:length(lineas_fuera) 
                    idx = lineas_fuera(k);

                    % Calcula admitancia de esa linea
                    L_km = T_lineas.Longitud_km(idx);
                    R_ohm_km = T_lineas.R_km(idx);
                    X_ohm_km = T_lineas.X_km(idx);
                    B_uS_km  = T_lineas.B_uS_km(idx);
                    
                    z_actual_serie = (R_ohm_km + 1j * X_ohm_km) * L_km;
                    y_actual_shunt_total = 1j * (B_uS_km * 1e-6) * L_km;
                    
                    Vbase = Vbase_bus(bus_i_falla); 
                    Zbase = (Vbase^2) / Sbase;
                    Ybase = 1 / Zbase;
                    
                    z_pu_serie = z_actual_serie / Zbase;
                    y_pu_shunt_total = y_actual_shunt_total / Ybase;
                    y_pu_serie = 1 / z_pu_serie;
                    y_pu_shunt_lado = y_pu_shunt_total / 2;
                    
                    % Se resta el bloque donde la linea quedo fuera de servicio
                    if (L_km >= 80) && (1 == shunt_modelo) % Si es modelo PI
                        Ybarra_contingencia(bus_i_falla, bus_i_falla) = Ybarra_contingencia(bus_i_falla, bus_i_falla) - (y_pu_serie + y_pu_shunt_lado);
                        Ybarra_contingencia(bus_j_falla, bus_j_falla) = Ybarra_contingencia(bus_j_falla, bus_j_falla) - (y_pu_serie + y_pu_shunt_lado);
                    else
                        Ybarra_contingencia(bus_i_falla, bus_i_falla) = Ybarra_contingencia(bus_i_falla, bus_i_falla) - y_pu_serie;
                        Ybarra_contingencia(bus_j_falla, bus_j_falla) = Ybarra_contingencia(bus_j_falla, bus_j_falla) - y_pu_serie;
                    end
                        Ybarra_contingencia(bus_i_falla, bus_j_falla) = Ybarra_contingencia(bus_i_falla, bus_j_falla) + y_pu_serie; 
                        Ybarra_contingencia(bus_j_falla, bus_i_falla) = Ybarra_contingencia(bus_j_falla, bus_i_falla) + y_pu_serie;
                end

                disp('--- Ybarra de Contingencia (Línea Fuera) ---');
                disp(Ybarra_contingencia);
            end
    
        case 2      % SACAR UN TRANSFORMADOR (El código busca, recalcula y resta el trafo)
            bus_i_falla = input('Ingrese el número de la barra "i" (De mayor tensión): ');
            bus_j_falla = input('Ingrese el número de la barra "j" (De menor tensión): ');
            
            trafos_fuera = find((T_trafos.barra_i == bus_i_falla & T_trafos.barra_j == bus_j_falla) | ...
                              (T_trafos.barra_i == bus_j_falla & T_trafos.barra_j == bus_i_falla));
                              
            if isempty(trafos_fuera)
                warning('No se encontró ningún transformador entre esos buses.');
            else
                
                for k = 1:length(trafos_fuera)
                    idx = trafos_fuera(k);

                    Z_pu_propio = (T_trafos.Impedancia_Alta_Media_Nom_PS(idx))/100; % Impedancia (R+jX) o Xps en base propia en p.u
                    Sbase_trafo = T_trafos.CapacidadNominal_MVA_(idx);  % MVA base del trafo
                    Vbase_trafo = T_trafos.Tensi_nNominal_kV_(idx);     % kV base del trafo
            
                    % Datos para Item (d) con Tap y Desfase
                    grupo_conexion = T_trafos.GRUPODECONEXI_N(idx);   % Grupo de conexión (0, 1, 11, etc.)
                    paso_por_tap_porcentaje = T_trafos.PasoPorTAP___(idx); % Paso por TAP [%]
                    paso_por_tap_pu = paso_por_tap_porcentaje / 100; % Paso por TAP en p.u

                    % Se vuelve a calcular la admitancia del tranfo o de varios tranfos que se sacan (si estan en paralelo)
                    switch lower(tap_escenario)
                        case 'nominal'
                            t = 1.0; % Tap nominal
                        case 'max'
                            t = 1.0 + paso_por_tap_pu*12; % "Paso por TAP p.u" es el incremento del 9 a 21
                        case 'min'
                            t = 1.0 - paso_por_tap_pu*8; %  "Paso por TAP p.u" es la disminución del paso 9 a 1
                    end
                    
                    tap_lado = T_trafos.VoltajePasoNominal_kV_{idx}; % Lado del tap: 'i' o 'j'
        
                    % 1. Recalcular Z_pu a la base del sistema (Sbase = 150 MVA)
                    Vbase_sistema = Vbase_bus(bus_i_falla);       % Vbase (kV) de (barra_i) que es de mayor tensión
                    Z_pu_nuevo = Z_pu_propio * 1j * (Sbase / Sbase_trafo)*(Vbase_trafo / Vbase_sistema)^2; % la barra donde es 230 algunos transfo la nominal son 220
                    
                    % 2. Obtener admitancia serie (y_t)
                    y_t = 1 / Z_pu_nuevo;
                    
                    % 3. Calcular Relación de Transformación Compleja (a) si (a = t * e^(j*delta))
                    delta_grados = grupo_conexion * (-30); % Desfase del transformador correspondiente: k * -30 grados
                    delta_rad = delta_grados * (pi / 180);
                    
                    a_complex = t * exp(1j * delta_rad);  % a = c si fuese regulante de angulo o magnitud
                    a_conjugado = conj(a_complex);        % a* = c* si fuese regulante de angulo o magnitud
                    
                    % 4. Ensamblar en Ybarra (Modelo del transformador con TAP y DESFASE seleccionado)    
                    % Se resta el bloque donde el transformador quedo fuera de servicio
                    if strcmpi(tap_lado, '220') % Tap en lado i (Primario)
                        Ybarra_contingencia(bus_i_falla, bus_i_falla) = Ybarra_contingencia(bus_i_falla, bus_i_falla) - (t^2) * y_t;
                        Ybarra_contingencia(bus_j_falla, bus_j_falla) = Ybarra_contingencia(bus_j_falla, bus_j_falla) - y_t;
                        Ybarra_contingencia(bus_i_falla, bus_j_falla) = Ybarra_contingencia(bus_i_falla, bus_j_falla) + a_conjugado * y_t;
                        Ybarra_contingencia(bus_j_falla, bus_i_falla) = Ybarra_contingencia(bus_j_falla, bus_i_falla) + a_complex * y_t;

                    elseif strcmpi(tap_lado, '115') % Tap en lado j (Secundario)
                        Ybarra_contingencia(bus_i_falla, bus_i_falla) = Ybarra_contingencia(bus_i_falla, bus_i_falla) - y_t;
                        Ybarra_contingencia(bus_j_falla, bus_j_falla) = Ybarra_contingencia(bus_j_falla, bus_j_falla) - (t^2) * y_t;
                        Ybarra_contingencia(bus_i_falla, bus_j_falla) = Ybarra_contingencia(bus_i_falla, bus_j_falla) + a_complex * y_t;
                        Ybarra_contingencia(bus_j_falla, bus_i_falla) = Ybarra_contingencia(bus_j_falla, bus_i_falla) + a_conjugado * y_t;

                    else % Default: Asumir tap en lado 'i' si no se especifica
                        warning('Lado del tap no especificado para trafo %d-%d. Asumiendo lado i.', bus_i, bus_j);
                        Ybarra_contingencia(bus_i_falla, bus_i_falla) = Ybarra_contingencia(bus_i_falla, bus_i_falla) - (t^2) * y_t;
                        Ybarra_contingencia(bus_j_falla, bus_j_falla) = Ybarra_contingencia(bus_j_falla, bus_j_falla) - y_t;
                        Ybarra_contingencia(bus_i_falla, bus_j_falla) = Ybarra_contingencia(bus_i_falla, bus_j_falla) + a_conjugado * y_t;
                        Ybarra_contingencia(bus_j_falla, bus_i_falla) = Ybarra_contingencia(bus_j_falla, bus_i_falla) + a_complex * y_t;
                    end
                end
                disp('--- Ybarra de Contingencia (Trafo Fuera) ---');
                disp(Ybarra_contingencia);
            end
            
        case 3            % SALIR SIN CAMBIOS
            disp('Operación cancelada. No se modificará la Ybarra base.');
        otherwise
            disp('Opción no válida.');
    end

if issymmetric(Ybarra_contingencia)
    disp('✅ La matriz Ybarra es simétrica. Cumple');
else
    disp('❌ La matriz Ybarra NO es simétrica.');
end

suma_filas = sum(Ybarra_contingencia, 2);  % Sumar cada fila

tolerancia = 1e-6;  % Pequeño margen de error numérico
if all(abs(suma_filas) < tolerancia)
    disp('✅ Se cumple la ley de Kirchhoff (suma de filas es cero).');
else
    disp('❌ La ley de Kirchhoff NO se cumple. Revisa la matriz Ybarra. Si hay elementos Shunt no se cumplirá');
end

if abs(det(Ybarra_contingencia)) > 1e-10
        disp('✅ La matriz es inversible.');
        esInversible = true;
    else
        disp('❌ La matriz NO es inversible (determinante es cero o muy cercano).');
        esInversible = false;
end


%%SEGUNDA PARTE: FLUJO DE CARGA (NEWTON-RAPHSON) ROBUSTO
%% ========================================================================
disp('----------------------------------------------------');
disp('Iniciando Flujo de Carga Newton-Raphson...');

% --- 1. Parámetros Generales ---
Sbase = 150; % Confirmamos la base
max_iter = 100; % Damos un poco más de margen
tolerancia = 1e-4; % Tolerancia estándar para empezar

% Cargar datos de Potencia 
Potencias = readtable('Tabla_potencias_oct.xlsm', 'Sheet', 2);
Pg = (Potencias.PotenciaActivaGenerada_MW_)' / Sbase;
Qg = (Potencias.PotenciaReactivaGenerada_MVAr_)' / Sbase;
Pd = (Potencias.PotenciaActiva_MW_)' / Sbase;
Qd = (Potencias.PotenciaReactiva_MVAr_)' / Sbase;

% Potencia neta programada
Pprog = Pg - Pd;
Qprog = Qg - Qd;

% Definición de tipos de barra (1: Slack, 2: PQ, 3: PV)
tipo_de_barra = [1 2 3 2 2 2 2 3 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 3];

% --- 2. DEFINICIÓN DE LÍMITES REACTIVOS (P.U.) ---
% Inicializamos límites muy abiertos para las que no son PV
Qg_min = -9999 * ones(1, N_barras);
Qg_max =  9999 * ones(1, N_barras);

% ASIGNACIÓN DE LÍMITES ESPECÍFICOS (Divididos por Sbase)
% Barra 3
Qg_min(3) = -110 / Sbase; 
Qg_max(3) =  124 / Sbase;
% Barra 8
Qg_min(8) = -25.2 / Sbase; 
Qg_max(8) =  29.2 / Sbase;
% Barra 25
Qg_min(25) = -125 / Sbase; 
Qg_max(25) =  122 / Sbase;

disp(['Limites Barra 3 (p.u): ' num2str(Qg_min(3)) ' a ' num2str(Qg_max(3))]);

% --- 3. INICIALIZACIÓN ---
V = ones(1, N_barras);
delta = zeros(1, N_barras);

idx_Slack = find(tipo_de_barra == 1);
idx_PV_orig = find(tipo_de_barra == 3);

% Ajuste inicial de tensiones conocidas
V(idx_Slack) = 1.0;    % Slack (generalmente 1.0)
V(idx_PV_orig) = 1.02; % Valor setpoint generadores (ajustar según datos reales)

tipo_actual = tipo_de_barra; % Vector dinámico para cambios PV -> PQ

convergio = false;
iter = 0;

% --- 4. BUCLE ITERATIVO ---
while iter < max_iter && ~convergio
    iter = iter + 1;
    
    % A. Calcular Potencias Calculadas (Pcal, Qcal)
    Pcal = zeros(1, N_barras);
    Qcal = zeros(1, N_barras);
    
    for i = 1:N_barras
        for j = 1:N_barras
            % Variable auxiliar común
            Yij_mag = abs(Ybarra_contingencia(i,j));
            Yij_ang = angle(Ybarra_contingencia(i,j));
            theta_ij = Yij_ang + delta(j) - delta(i);
            
            term = V(i) * V(j) * Yij_mag;
            
            Pcal(i) = Pcal(i) + term * cos(theta_ij);
            Qcal(i) = Qcal(i) - term * sin(theta_ij);
        end
    end
    
    % B. Chequeo de Límites Q (Solo para barras originalmente PV)
    % Se recomienda no aplicar esto en la primera iteración para dejar que V se ajuste
    if iter > 2
        for k = idx_PV_orig
            % Q que debe entregar el generador = Qcal (inyectada a la red) + Qd (carga local)
            Q_gen_req = Qcal(k) + Qd(k);
            
            if tipo_actual(k) == 3 % Si es PV, verificamos si viola
                if Q_gen_req > Qg_max(k)
                    disp(['Iter ' num2str(iter) ': Barra ' num2str(k) ' viola Qmax. Pasa a PQ (Q=' num2str(Qg_max(k)) ')']);
                    tipo_actual(k) = 2; % Cambia a PQ
                    Qprog(k) = Qg_max(k) - Qd(k); % Se fija Q inyectado
                elseif Q_gen_req < Qg_min(k)
                    disp(['Iter ' num2str(iter) ': Barra ' num2str(k) ' viola Qmin. Pasa a PQ (Q=' num2str(Qg_min(k)) ')']);
                    tipo_actual(k) = 2; % Cambia a PQ
                    Qprog(k) = Qg_min(k) - Qd(k);
                end
            else % Si ya es PQ (limitada), verificamos si puede volver a ser PV
                % Esta lógica ("back-off") es opcional, por ahora dejemos que se quede limitada
                % para asegurar convergencia.
            end
        end
    end
    
    % C. Vector de Mismatches (Residuos)
    dP = Pprog - Pcal;
    dQ = Qprog - Qcal;
    
    % Identificar incógnitas
    % Incógnitas Delta: Todas menos Slack
    idx_delta = 2:N_barras; 
    % Incógnitas Voltaje: Solo las PQ (incluyendo PV limitadas)
    idx_V = find(tipo_actual == 2);
    
    % Vector Mismatch reducido
    mismatch = [dP(idx_delta)'; dQ(idx_V)'];
    
    error_max = max(abs(mismatch));
    if error_max < tolerancia
        convergio = true;
        break;
    end
    
    % D. Construcción del Jacobiano (Formulación Polar Completa)
    % J = [H  N]  -> dP/ddelta   dP/dV*V
    %     [M  L]  -> dQ/ddelta   dQ/dV*V
    
    H = zeros(N_barras, N_barras);
    N_mat = zeros(N_barras, N_barras);
    M_mat = zeros(N_barras, N_barras);
    L = zeros(N_barras, N_barras);
    
    for i = 1:N_barras
        for j = 1:N_barras
            Yij_mag = abs(Ybarra_contingencia(i,j));
            Yij_ang = angle(Ybarra_contingencia(i,j));
            theta_ij = Yij_ang + delta(j) - delta(i);
            
            if i ~= j
                % Elementos fuera de la diagonal
                H(i,j) = -V(i) * V(j) * Yij_mag * sin(theta_ij);
                N_mat(i,j) = V(i) * V(j) * Yij_mag * cos(theta_ij);
                M_mat(i,j) = -V(i) * V(j) * Yij_mag * cos(theta_ij);
                L(i,j) = -V(i) * V(j) * Yij_mag * sin(theta_ij);
            else
                % Elementos de la diagonal
                % H_ii = -Q_cal_i - B_ii * V_i^2
                H(i,i) = -Qcal(i) - (V(i)^2) * imag(Ybarra_contingencia(i,i));
                
                % N_ii = P_cal_i + G_ii * V_i^2
                N_mat(i,i) = Pcal(i) + (V(i)^2) * real(Ybarra_contingencia(i,i));
                
                % M_ii = P_cal_i - G_ii * V_i^2
                M_mat(i,i) = Pcal(i) - (V(i)^2) * real(Ybarra_contingencia(i,i));
                
                % L_ii = Q_cal_i - B_ii * V_i^2
                L(i,i) = Qcal(i) - (V(i)^2) * imag(Ybarra_contingencia(i,i));
            end
        end
    end
    
    % E. Reducción y Solución
    H_red = H(idx_delta, idx_delta);
    N_red = N_mat(idx_delta, idx_V);
    M_red = M_mat(idx_V, idx_delta);
    L_red = L(idx_V, idx_V);
    
    J_final = [H_red, N_red; M_red, L_red];
    
    % Paso de corrección
    correction = J_final \ mismatch;
    
    % F. Actualización de Estado
    n_ang = length(idx_delta);
    d_delta = correction(1:n_ang);
    dV_over_V = correction(n_ang+1:end); % Esto es dV/V
    
    delta(idx_delta) = delta(idx_delta) + d_delta';
    V(idx_V) = V(idx_V) .* (1 + dV_over_V'); % Actualización multiplicativa
    
    disp(['Iter ' num2str(iter) ' - Error: ' num2str(error_max)]);
end

if convergio
    disp(['✅ Convergencia exitosa en iteración ' num2str(iter)]);
else
    disp('❌ El sistema NO convergió. Revisa Ybarra o Potencias extremas.');
end

%% 5. MOSTRAR RESULTADOS
disp('Resultados finales de Tensión y Generación:');
V_complex = V .* exp(1j * delta);
fprintf('%4s | %8s | %8s | %10s | %10s\n', 'Bus', 'V(pu)', 'Ang(°)', 'Pgen(MW)', 'Qgen(MVAr)');
for k=1:N_barras
    S_inyectada = V_complex(k) * conj(sum(Ybarra_contingencia(k,:) .* V_complex));
    Pg_calc_MW = (real(S_inyectada) + Pd(k)) * Sbase;
    Qg_calc_MVAR = (imag(S_inyectada) + Qd(k)) * Sbase;
    
    fprintf('%4d | %8.4f | %8.4f | %10.2f | %10.2f\n', ...
        k, abs(V(k)), delta(k)*180/pi, Pg_calc_MW, Qg_calc_MVAR);
end
%% ========================================================================
%% 6. GENERACIÓN DE REPORTES PARA LA TABLA (ENTREGA)
%% ========================================================================
disp(' ');
disp('====================================================================');
disp('             TABLA 1: PERFIL DE TENSIONES (Copiar a Excel)');
disp('====================================================================');
fprintf('%s\t%s\n', 'Barra', 'Tension (p.u.)'); % Cabecera con tabulaciones

for k = 1:N_barras
    % Imprime: Numero de Barra [TAB] Magnitud de Tensión
    fprintf('%d\t%.5f\n', k, abs(V(k)));
end

disp(' ');
disp('====================================================================');
disp('             TABLA 2: CARGABILIDAD DE ELEMENTOS');
disp('====================================================================');
disp('--- LÍNEAS DE TRANSMISIÓN ---');
fprintf('%s\t%s\t%s\t%s\n', 'Barra Ini', 'Barra Fin', 'Flujo (MVA)', 'Cargabilidad (%)');

% Recorremos la tabla original de líneas para calcular flujo real en cada una
for i = 1:height(T_lineas)
    b_i = T_lineas.barra_i(i);
    b_j = T_lineas.barra_j(i);
    
    if exist('tipo_contingencia', 'var') && tipo_contingencia == 1
        % Verificar si coincide en cualquier dirección (i-j o j-i)
        if (b_i == bus_i_falla && b_j == bus_j_falla) || ...
           (b_i == bus_j_falla && b_j == bus_i_falla)
            fprintf('%d\t%d\t%s\t%s\n', b_i, b_j, '----', 'FUERA DE SERVICIO');
            continue; % Pasa a la siguiente iteración del for
        end
    end

    % 1. Recalcular parámetros de la línea individual (como en la Entrega 1)
    L_km = T_lineas.Longitud_km(i);
    Z_serie_ohm = (T_lineas.R_km(i) + 1j*T_lineas.X_km(i)) * L_km;
    Y_shunt_uS  = 1j * (T_lineas.B_uS_km(i) * 1e-6) * L_km;
    
    % Bases locales
    Vbase_linea = Vbase_bus(b_i); 
    Zbase_linea = Vbase_linea^2 / Sbase;
    Ybase_linea = 1 / Zbase_linea;
    
    % Parámetros en p.u.
    z_pu = Z_serie_ohm / Zbase_linea;
    y_sh_pu = (Y_shunt_uS / Ybase_linea) / 2; % Mitad en cada extremo
    
    % 2. Calcular Voltajes Complejos en los extremos
    Vi_c = V(b_i) * exp(1j * delta(b_i));
    Vj_c = V(b_j) * exp(1j * delta(b_j));
    
    % 3. Corriente y Flujo de Potencia (Sij)
    % Corriente serie = (Vi - Vj) / z_pu
    % Corriente shunt = Vi * y_sh_pu
    
    if (1 == shunt_modelo)
            I_ij_pu = (Vi_c - Vj_c)/z_pu + Vi_c * y_sh_pu; % Corriente saliendo de i
            I_ji_pu = (Vj_c - Vi_c)/z_pu + Vj_c * y_sh_pu; % Corriente saliendo de j (hacia i)          
        else 
            I_ji_pu = (Vj_c - Vi_c)/z_pu;
            I_ij_pu = (Vi_c - Vj_c)/z_pu;
    end

    S_ij_pu = Vi_c * conj(I_ij_pu);
    S_ij_MVA = abs(S_ij_pu) * Sbase;
    
    % 4. Obtener Límite (Tomamos el flujo de corriente MÁXIMO en p.u. (en cualquiera de los dos extremos))
    I_flow_max_pu = max(abs(I_ij_pu), abs(I_ji_pu));

    try
        % Valor extraido de la tabla
        Limite_A = T_lineas.L_miteT_rmico_A_(i); 
    catch
        warning('Columna Limite_A no encontrada. Asumiendo 1000A.');
        Limite_A = 1000; % Valor por defecto si falla la lectura
    end
    
    % Usamos la Vbase de la barra 'i' (kV)
    Ibase_A = (Sbase * 1000) / (sqrt(3) * Vbase_bus(b_i)); 
    
    % Límite térmico en p.u.
    I_limite_pu = Limite_A / Ibase_A;
    
    % 5. Calcular Porcentaje de Cargabilidad
    Cargabilidad = (I_flow_max_pu / I_limite_pu) * 100;
    
    % Imprimir fila
    fprintf('%d\t%d\t%.2f\t%.2f%%\n', b_i, b_j, S_ij_MVA, Cargabilidad);

end

disp(' ');
disp('--- TRANSFORMADORES ---');
fprintf('%s\t%s\t%s\t%s\n', 'Barra AT', 'Barra BT', 'Flujo (MVA)', 'Cargabilidad (%)');


for k = 1:height(T_trafos)
    b_i = T_trafos.barra_i(k); 
    b_j = T_trafos.barra_j(k);
    Capacidad_MVA = T_trafos.CapacidadNominal_MVA_(k);
    
    % Usar el tap exacto guardado
    t = Tap_usados_vector(k);
    
    Z_pu_propio = (T_trafos.Impedancia_Alta_Media_Nom_PS(k))/100;
    Vbase_trafo_prim = T_trafos.Tensi_nNominal_kV_(k);
    Z_pu_sis = Z_pu_propio * 1j * (Sbase / Capacidad_MVA) * (Vbase_trafo_prim / Vbase_bus(b_i))^2;
    y_t = 1 / Z_pu_sis;

    grupo_conexion = T_trafos.GRUPODECONEXI_N(k);
    a_complex = t * exp(1j * grupo_conexion * -30 * (pi/180));
    a_conjugado = conj(a_complex);
    
    Vi_c = V(b_i) * exp(1j * delta(b_i));
    Vj_c = V(b_j) * exp(1j * delta(b_j));
    
    tap_lado = T_trafos.VoltajePasoNominal_kV_{k};

    % Cálculo riguroso de corriente inyectada usando ecuaciones de Ybarra
    if strcmpi(tap_lado, '220') 
        I_ij_pu = (t^2 * y_t) * Vi_c + (-a_conjugado * y_t) * Vj_c;
    elseif strcmpi(tap_lado, '115')
        I_ij_pu = (y_t) * Vi_c + (-a_complex * y_t) * Vj_c;
    else
        I_ij_pu = (t^2 * y_t) * Vi_c + (-a_conjugado * y_t) * Vj_c;
    end
    
    S_flujo_pu = Vi_c * conj(I_ij_pu); 
    S_MVA_Calc = abs(S_flujo_pu) * Sbase;
    Cargabilidad = (S_MVA_Calc / Capacidad_MVA) * 100;
    
    fprintf('%d\t%d\t%.2f\t%.2f%%\n', b_i, b_j, S_MVA_Calc, Cargabilidad);
end

%% ========================================================================
%% 7. RESUMEN DE CONTINGENCIA (PARA COPIAR A EXCEL)
%% ========================================================================
% Este bloque busca automáticamente:
% 1. El elemento más cargado del sistema (Línea o Trafo).
% 2. La tensión más crítica (la más baja).

% --- A. BUSCAR LA TENSIÓN MÁS CRÍTICA (Mínima) ---
[V_min_val, V_min_idx] = min(abs(V)); % Encuentra el valor mínimo y su índice (barra)

% --- B. BUSCAR LA MÁXIMA CARGABILIDAD (Recalculo rápido) ---
Max_Carg = 0;
Elem_Max_Str = '';
Bi_Max = 0;
Bj_Max = 0;

% 1. Revisar Líneas
for i = 1:height(T_lineas)
    b_i = T_lineas.barra_i(i);
    b_j = T_lineas.barra_j(i);
    
    % Si es la línea de la contingencia, la saltamos
    if exist('tipo_contingencia', 'var') && tipo_contingencia == 1
        if (b_i == bus_i_falla && b_j == bus_j_falla) || (b_i == bus_j_falla && b_j == bus_i_falla)
            continue; 
        end
    end

    % Cálculos básicos para obtener cargabilidad
    L_km = T_lineas.Longitud_km(i);
    Z_serie = (T_lineas.R_km(i) + 1j*T_lineas.X_km(i)) * L_km;
    Y_shunt = 1j * (T_lineas.B_uS_km(i) * 1e-6) * L_km;
    Vbase_linea = Vbase_bus(b_i);
    Zbase_linea = Vbase_linea^2 / Sbase; 
    Ybase_linea = 1/Zbase_linea;
    z_pu = Z_serie / Zbase_linea;
    y_sh_pu = (Y_shunt / Ybase_linea) / 2;
    
    Vi_c = V(b_i) * exp(1j * delta(b_i));
    Vj_c = V(b_j) * exp(1j * delta(b_j));
    
    if (1 == shunt_modelo)
        I_ij = (Vi_c - Vj_c)/z_pu + Vi_c * y_sh_pu;
        I_ji = (Vj_c - Vi_c)/z_pu + Vj_c * y_sh_pu;
    else
        I_ij = (Vi_c - Vj_c)/z_pu;
        I_ji = (Vj_c - Vi_c)/z_pu;
    end
    
    I_max_abs = max(abs(I_ij), abs(I_ji));
    
    try Lim_A = T_lineas.L_miteT_rmico_A_(i); catch, Lim_A = 1000; end
    Ibase_A = (Sbase * 1000) / (sqrt(3) * Vbase_bus(b_i));
    Carg_Line = (I_max_abs / (Lim_A / Ibase_A)) * 100;
    
    if Carg_Line > Max_Carg
        Max_Carg = Carg_Line;
        Bi_Max = b_i;
        Bj_Max = b_j;
        Elem_Max_Str = 'Línea';
    end
end

% 2. Revisar Transformadores
for k = 1:height(T_trafos)
    % Si es el trafo de la contingencia, lo saltamos (si aplica lógica N-1 de trafo)
    b_i = T_trafos.barra_i(k);
    b_j = T_trafos.barra_j(k);
    
    if exist('tipo_contingencia', 'var') && tipo_contingencia == 2
        % Verificar si es el trafo sacado (asumiendo lógica similar a líneas)
        % Nota: Tu código original de contingencia trafo recalcula Ybarra pero 
        % aquí solo chequeamos flujos. Si la Ybarra ya no tiene el trafo, 
        % el flujo calculado aquí podría ser erróneo si no se salta.
        % Se asume que si se sacó, no hay flujo, pero por seguridad:
        if (b_i == bus_i_falla && b_j == bus_j_falla) || (b_i == bus_j_falla && b_j == bus_i_falla)
             continue; 
        end
    end

    Cap_MVA = T_trafos.CapacidadNominal_MVA_(k);
    t = Tap_usados_vector(k);
    Z_pu_propio = (T_trafos.Impedancia_Alta_Media_Nom_PS(k))/100;
    Vbase_prim = T_trafos.Tensi_nNominal_kV_(k);
    Z_pu_sis = Z_pu_propio * 1j * (Sbase / Cap_MVA) * (Vbase_prim / Vbase_bus(b_i))^2;
    y_t = 1 / Z_pu_sis;
    grupo = T_trafos.GRUPODECONEXI_N(k);
    a_c = t * exp(1j * grupo * -30 * (pi/180));
    
    Vi_c = V(b_i) * exp(1j * delta(b_i));
    Vj_c = V(b_j) * exp(1j * delta(b_j));
    
    tap_lado = T_trafos.VoltajePasoNominal_kV_{k};
    if strcmpi(tap_lado, '220')
        I_ij = (t^2 * y_t) * Vi_c + (-conj(a_c) * y_t) * Vj_c;
    elseif strcmpi(tap_lado, '115')
        I_ij = (y_t) * Vi_c + (-a_c * y_t) * Vj_c;
    else
        I_ij = (t^2 * y_t) * Vi_c + (-conj(a_c) * y_t) * Vj_c;
    end
    
    S_calc = abs(Vi_c * conj(I_ij)) * Sbase;
    Carg_Trafo = (S_calc / Cap_MVA) * 100;
    
    if Carg_Trafo > Max_Carg
        Max_Carg = Carg_Trafo;
        Bi_Max = b_i;
        Bj_Max = b_j;
        Elem_Max_Str = 'Trafo';
    end
end

if convergio
    disp(['✅ Convergencia exitosa en iteración ' num2str(iter)]);
else
    disp('❌ El sistema NO convergió. Revisa Ybarra o Potencias extremas.');
end
% --- IMPRIMIR TABLA ---
disp(' ');
disp('COPIAR ESTA TABLA A EXCEL (RESUMEN DE CONTINGENCIA):');
fprintf('Barra ini\tBarra Fin\tCargabilidad máx\tElemento\tTensión crítica\tBarra\n');
fprintf('%d\t%d\t%.2f%%\t%s %d-%d\t%.4f\t%d\n', ...
    Bi_Max, Bj_Max, Max_Carg, Elem_Max_Str, Bi_Max, Bj_Max, V_min_val, V_min_idx);

