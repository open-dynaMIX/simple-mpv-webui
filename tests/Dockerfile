FROM python:3.9.1

RUN mkdir -p /app \
#    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 90BD7EACED8E640A \
#    && apt-get update \
#    && apt-get install --no-install-recommends -y software-properties-common \
#    && add-apt-repository -y ppa:mc3man/mpv-tests \
    && apt-get update \
    && apt-get install --no-install-recommends -y mpv lua-socket

COPY . /app

WORKDIR /app/tests

RUN pip install --no-cache-dir --upgrade -r requirements.txt --disable-pip-version-check

EXPOSE 8080

CMD mpv --config-dir=./environment/ ./environment/test_media/*\ -\ dummy.mp3