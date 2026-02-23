FROM public.ecr.aws/docker/library/python:3.14.3-alpine3.23
WORKDIR /
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8080
CMD ["gunicorn", "hello:create_app()"]
