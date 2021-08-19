FROM python:3.9.0-buster

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt

RUN apt update -y -qq

RUN apt install curl -y -qq

COPY app /usr/src/app/

EXPOSE 5000

ENTRYPOINT ["python", "/usr/src/app/app.py"]
