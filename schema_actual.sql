supabase : Initialising login role...
En línea: 1 Carácter: 1
+ supabase db dump --linked --schema public 2>&1 | Out-File "C:\Users\L ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Initialising login role...:String 
   ) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
Dumping schemas from remote database...
failed to inspect docker image: error during connect: in the default daemon 
configuration on Windows, the docker client must be run with elevated 
privileges to connect: Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.51/images/
public.ecr.aws/supabase/postgres:17.6.1.084/json": open 
//./pipe/docker_engine: The system cannot find the file specified.
Docker Desktop is a prerequisite for local development. Follow the official 
docs to install: https://docs.docker.com/desktop
