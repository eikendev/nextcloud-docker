# About

This is my extension of the official [Docker image for Nextcloud](https://github.com/nextcloud/docker).
In fact, it uses the official image as a base, to which I've added a personal touch.

My image provides two security-related improvements over the default image.
- The file permissions of the Nextcloud installation are set as strictly as possible. This should make it harder for attackers to write to executed files.
- The web server runs under a non-privileged user. Thereby, a non-privileged port is used to expose the service.

Further, the image does not use a volume that contains the files for the Nextcloud server.
Instead, those files are copied into the web server root during the build, after which appropriate permissions are set.
Of course, this excludes directories like `config`, `data`, and `custom_apps`, because these are user-dependent and will be added afterwards

Another difference is that I removed the installation process from the entrypoint, because I feel like I don't need that much complexity for my personal use.
