FROM danigoland/py36-alpine-llvm6 as stage_0

RUN apk add --no-cache --virtual .build-deps \
  build-base libffi-dev unzip openblas-dev freetype-dev pkgconfig gfortran g++ libressl-dev \
  && ln -s /usr/include/locale.h /usr/include/xlocale.h
RUN apk add --no-cache linux-headers
RUN pip install --no-cache-dir tweepy jupyter neomodel

RUN find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
                | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                | sort -u \
                | xargs -r apk info --installed \
                | sort -u \
    )" \
    && apk add --virtual .rundeps $runDeps tzdata tini \
    && apk del .build-deps

RUN mkdir -p /home/ioc-workshop && addgroup -S ioc-workshop-group && adduser -S ioc-workshop -G ioc-workshop-group && chown -R ioc-workshop:ioc-workshop-group /home/ioc-workshop
WORKDIR /home/ioc-workshop
USER ioc-workshop
COPY tweets.json new_tweets.json new_tweets2.json querying.ipynb streaming.ipynb analysis.ipynb ./


ENTRYPOINT ["tini", "--"]


EXPOSE 8888

CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]