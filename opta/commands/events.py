import datetime
from typing import Optional

import click
import pytz

from opta.amplitude import amplitude_client
from opta.commands.apply import _local_setup
from opta.core.generator import gen_all
from opta.core.kubernetes import (
    load_opta_kube_config,
    set_kube_config,
    tail_namespace_events,
)
from opta.layer import Layer
from opta.utils.clickoptions import local_option


@click.command(hidden=True)
@click.option(
    "-e", "--env", default=None, help="The env to use when loading the config file"
)
@click.option(
    "-c", "--config", default="opta.yaml", help="Opta config file", show_default=True
)
@click.option(
    "-s",
    "--seconds",
    default=None,
    help="Start showing events from these many seconds in the past",
    show_default=False,
    type=int,
)
@local_option
def events(
    env: Optional[str], config: str, seconds: Optional[int], local: Optional[bool]
) -> None:
    """
    List the events for a service

    Examples:

    opta events -c my-service.yaml

    """
    if local:
        config = _local_setup(config)
    # Configure kubectl
    layer = Layer.load_from_yaml(config, env)
    amplitude_client.send_event(
        amplitude_client.SHELL_EVENT,
        event_properties={"org_name": layer.org_name, "layer_name": layer.name},
    )
    start_time = None
    if seconds:
        start_time = pytz.utc.localize(datetime.datetime.min) - datetime.timedelta(
            seconds=seconds
        )
    layer.verify_cloud_credentials()
    gen_all(layer)
    set_kube_config(layer)
    load_opta_kube_config()
    tail_namespace_events(layer, start_time)
