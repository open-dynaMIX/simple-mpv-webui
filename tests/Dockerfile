FROM ubuntu:23.10

ENV MPV_HOME=/app

RUN mkdir -p $MPV_HOME/scripts/simple-mpv-webui \
    && apt-get update \
    && apt-get install --no-install-recommends -y python3-pip mpv lua-socket

COPY . $MPV_HOME/scripts/simple-mpv-webui
COPY tests/environment/mpv.conf $MPV_HOME/mpv.conf

WORKDIR $MPV_HOME/scripts/simple-mpv-webui/tests

RUN pip3 install \
    --no-cache-dir \
    --upgrade \
    -r requirements.txt \
    --disable-pip-version-check \
    --break-system-packages

EXPOSE 8080

CMD mpv --config-dir=./environment/ ./environment/test_media/*\ -\ dummy.mp3