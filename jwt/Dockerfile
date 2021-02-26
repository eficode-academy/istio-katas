FROM python:3.9.0-buster

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt

RUN mkdir /work
WORKDIR /work

COPY create-jwt.py /usr/src/app/

ENTRYPOINT ["python", "/usr/src/app/create-jwt.py"]
