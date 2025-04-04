# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM python:3.13.2-bookworm

RUN apt-get update && \
  apt-get --assume-yes --no-install-recommends install \
  locales \
  locales-all && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

COPY requirements.txt /srv/mesop-app/

WORKDIR /srv/mesop-app
RUN pip install --no-cache-dir -r requirements.txt

ARG UID=10000
ARG GID=10000

RUN groupadd -g "${GID}" mesop && useradd -u "${UID}" -s /bin/bash -g mesop mesop
USER mesop

COPY --chown=mesop:mesop . /srv/mesop-app

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--reload", "main:me"]
