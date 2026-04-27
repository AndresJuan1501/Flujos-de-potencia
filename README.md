# Análisis de Flujos de Potencia en Sistemas Eléctricos

Este repositorio contiene herramientas desarrolladas en **MATLAB** para realizar el cálculo y análisis de flujos de potencia en redes eléctricas. El script permite el modelado de sistemas de potencia estándar y configuraciones basadas en el **Sistema de Transmisión Nacional (STN) de Colombia**.

## Características Principales
* **Modelado de Redes:** Soporte para la configuración de barras de carga (PQ), barras de tension controlada (PV) y barra Slack (Slack).
* **Cálculo de Matriz de Admitancias:** Generación automática de la Ybarra (Ybus) a partir de los datos de las líneas, transformadores, reactores.
* **Análisis de Resultados:** Obtención de perfiles de tensión, ángulos de fase, flujos de potencia activa/reactiva y cálculo de pérdidas totales del sistema.
* **Versatilidad:** Capacidad para procesar sistemas de prueba de la IEEE o configuraciones personalizadas del sector eléctrico colombiano.

## Herramientas Utilizadas
* **MATLAB:** Motor principal para el procesamiento numérico y algoritmos de flujo.
* **Simulink:** (Opcional) Modelado complementario de componentes del sistema.

## Estructura del Proyecto
* `scripts/`: Contiene los archivos `.m` con la lógica del cálculo.
* `data/`: Archivos de entrada con los parámetros de barras y líneas.
* `results/`: Gráficas y reportes generados por las simulaciones.

## Instrucciones de Uso
1. Descargar o clonar este repositorio.
2. Abrir MATLAB y situarse en la carpeta del proyecto.
3. Ejecutar el script principal (`.m`).
4. Ingresar los datos del sistema cuando el programa lo solicite o cargar un archivo de datos predefinido.

## Autor
Este proyecto es desarrollado por **Andrés Juan Ortiz Jaimes**, estudiante de Ingeniería Eléctrica en la **Universidad Industrial de Santander (UIS)**. Mi enfoque profesional se orienta hacia la estabilidad de sistemas eléctricos, con el uso de la automatización de procesos de ingeniería mediante lenguajes como MATLAB, Python y C++.

---
*Nota: Este repositorio se encuentra en desarrollo activo para integrar métodos de solución más robustos (Newton-Raphson / Gauss-Seidel) y herramientas de visualización avanzada.*
