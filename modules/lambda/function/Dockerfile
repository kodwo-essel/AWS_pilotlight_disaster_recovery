# Use the official AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Set working directory
WORKDIR /var/task

# Copy function code and requirements
COPY failover_monitor.py .
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set the CMD to your handler function
CMD ["failover_monitor.lambda_handler"]
