FROM python:3.14-slim

RUN apt-get update && apt-get install -y \
    shellcheck \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Go Task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Install Ansible, ansible-lint, and pre-commit
COPY ansible/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    pip install --no-cache-dir pre-commit

WORKDIR /project

# Pre-populate pre-commit hook environments at build time.
# Copied first so this layer is only invalidated when the config changes.
COPY .pre-commit-config.yaml .
RUN git init && pre-commit install-hooks

# Copy the full project
COPY . .

# Stage all files so pre-commit can discover them, and ensure scripts are executable
RUN chmod +x seed/*.bash home-assistant/scripts/*.bash ansible/run-playbook.bash && git add -A

CMD ["sh", "-c", "task test && task lint"]
