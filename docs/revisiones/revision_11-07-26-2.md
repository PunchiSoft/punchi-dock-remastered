# Revisión del plasmoide

## primera revision:

- al añadir un "dock item" en "configure app" detecta correctamente, la busqueda de app e icono segun el alias y su respectiva descripcion corta si la tiene, pero no se guarda al momento de salir de ese formulario. revisar comportamiento.

- desktop visibility debe mostrar el estado actual, en el downlist "sinlge desktop", "all desktop"

- target desktop funciona perfecto pero debe mostrar por defecto preseleccionad como primera opcion el deskto actual en el que se encuentra el usuario.

- config-general, debe tener 2 parrafos de conguracion un parrafo debe tener un label con "modo flotante" , "modo panel" y estos deben ser detectados de forma automatica;
  - modo flotante:
    - tamaños de iconos con su delizador resepctivo
  - modo panel:
    - tamaño de iconos con su deslizador respectivo (este debe tener limites al tamaño del ancho del panel y un minimo estable) los limites de este delizador se deben calcular al ancho del panel respectivo para no romper visualmente la estetica.

- añadir config/mouse_hover donde deben ir un down list de las animaciones al pasar el mouse:
    - hover mouse anamacion:
        - none
        - wave
        - single
        - paragraph

- notas debe tener iconos en "clean" , "close" como es menu popup puede ser symbolic icon si esta disponible pero siempre adaptandose al color del tema plasma seleccionado.

- notas debe integrar "B: bold",  subrayado, cursivo como basico de texto enriquesido color no, selector de fuente auno no tampoco.

- ver posibilidad que el comando  "plasmoidviewer -a org.kde.plasma.punchi-dock-remastered" pueda actualizarse cuando detecte modificaciones el el plasma permitiendo una vista preliminar en vivo.
        