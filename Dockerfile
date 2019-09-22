FROM qixxit/elixir-centos as build
COPY . .

ENV MIX_ENV=prod

RUN yum install -y gcc-c++ make epel-release
RUN yum install nodejs
RUN npm install yarn -g

RUN rm -Rf _build && \
    mix deps.get &&\
    mix compile &&\
    mix reset_mnesia_schema

RUN cd assets && \
    npm install && \
    cd .. && \
    mix phx.digest

RUN mix release

RUN APP_NAME="football_seasons" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

FROM qixxit/elixir-centos
COPY --from=build /export/ .

ENTRYPOINT ["/opt/app/bin/football_seasons"]
CMD ["foreground"]
