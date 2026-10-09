# Con Personeros

Aplicación Flutter para registrar y consultar el conteo de votos de actas. La app
se conecta a una API Serverless desplegada en AWS.

## Requisitos

- Flutter y Dart compatibles con la versión indicada en `pubspec.yaml` (Dart
  `3.11.5` o superior dentro de la versión permitida por el proyecto).
- Git.
- Google Chrome para ejecutar la versión web.
- Android Studio, Android SDK y un emulador o dispositivo para ejecutar en
  Android.
- Acceso a la API de desarrollo o a un despliegue propio del backend.

Comprueba que Flutter esté disponible:

```bash
flutter doctor
```

## Descargar y preparar

```bash
git clone https://github.com/jhonazsh17/con_personeros.git
cd con_personeros
flutter pub get
```

`flutter pub get` instala las dependencias Dart declaradas por el proyecto.

## Ejecutar

Para ejecutar en Chrome:

```bash
flutter run -d chrome
```

Para Android, conecta un dispositivo o inicia un emulador y consulta los
dispositivos disponibles:

```bash
flutter devices
flutter run -d <id-del-dispositivo>
```

## Verificar y compilar

```bash
flutter analyze
flutter build web
flutter build apk
```

El resultado web se genera en `build/web`; el APK se genera en
`build/app/outputs/flutter-apk/`.

## Backend requerido

La infraestructura y API que utiliza la app están en el repositorio
[`con_personeros_iaas`](https://github.com/jhonazsh17/con_personeros_iaas). No es
una dependencia de `pubspec.yaml`: es el backend que debe estar desplegado y
accesible para que funcionen el login, el registro y la consulta de actas.

Si también necesitas descargar el backend:

```bash
git clone https://github.com/jhonazsh17/con_personeros_iaas.git
cd con_personeros_iaas
npm install
npm install -g serverless
npm run deploy
```

Para desplegarlo se requiere Node.js 20, Serverless Framework y credenciales de
AWS configuradas localmente mediante AWS CLI. Consulta el
[README del backend](https://github.com/jhonazsh17/con_personeros_iaas#readme)
para detalles de despliegue y configuración de feature flags. El flag
`enableNewVotingSystem` debe estar habilitado para que la app muestre el login.
No guardes credenciales de AWS en este repositorio.

El README del backend indica que sus endpoints no tienen autenticación y que
CORS está abierto. Antes de usarlo con datos reales o producción, configura
autenticación/autorización en el servidor y restringe CORS a los dominios
necesarios.

La app apunta inicialmente a esta API de desarrollo:

```text
https://4g1vps5k71.execute-api.us-east-1.amazonaws.com/dev
```

El servicio de la app consume estas rutas:

- `GET /feature-flags/enableNewVotingSystem`: habilita o bloquea el acceso a la
  aplicación. El feature flag debe devolver `enabled: true` para mostrar el
  login.
- `POST /users/login` y `POST /users/acta-registered`.
- `POST /records`, `PUT /records/{actaId}` y `GET /records`.
- `GET /votes/candidates`.

Para apuntar a otro despliegue, actualiza el host y la etapa (`stage`) en
`lib/services/api_service.dart`. La API debe permitir el origen de la app
mediante su configuración CORS.

## Uso

1. Inicia la app y espera la comprobación del feature flag.
2. Ingresa el DNI de un usuario previamente registrado en el backend.
3. Las opciones disponibles dependen del rol (`personero`, `coordinador` o
   `admin`).
4. Registra o consulta actas según los permisos del perfil.

La app no incluye usuarios de prueba. Los usuarios se administran desde el
backend; no publiques DNI reales, credenciales ni datos de votación en ejemplos
o capturas.
