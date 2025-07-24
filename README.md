# linux
Linux deployment and configuration scripts

## Docker network (standalone)

Declare network to use, which were created while intial procedure `docker\sysprep.sh`.
```yaml
networks:
  public_network: { external: true }
  private_network: { external: true }
```

Networks assignment for service.
```yaml
services:
  app1:
    image: myimage
    networks: [public_network, private_network]
  app2:
    image: my_image
    networks: [private_network]
```