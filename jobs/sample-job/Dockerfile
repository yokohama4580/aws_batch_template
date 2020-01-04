FROM python:3.7.4-slim
    
ENV TZ JST-9
ENV TERM xterm
ARG TARGET_JOB
ENV TARGET_JOB=$TARGET_JOB

WORKDIR /app

COPY ./jobs/$TARGET_JOB/app/ ./

RUN pip install --upgrade pip \
    && pip install -r ./requirements.txt

ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

ENTRYPOINT ["sh", "./entrypoint.sh"]