# Comgy Exporter

Prometheus exporter, that fetches the latest readout values
for all accessible meters.

## State of Project

Experimental / in development


## Usage

With docker compose:

```yml
services:
  comgy-exporter:
    build: "."
    restart: always
    ports:
      - 9111:9111
    environment:
      COMGY_ACCOUNT_MASTER_KEY: <token>
```

## Example metric output

```
# HELP comgy_meter_value Latest meter value
# TYPE comgy_meter_value gauge
comgy_meter_value{meter_identifier="12345678"} 0.096
```
