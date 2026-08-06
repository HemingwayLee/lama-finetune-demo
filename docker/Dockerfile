FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget mc tmux nano build-essential rsync libgl1 \
        python3-pip python3-dev

ARG USERNAME=user
RUN apt-get install -y sudo && \
    addgroup --gid 1000 $USERNAME && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos '' $USERNAME && \
    adduser $USERNAME sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    USER=$USERNAME && \
    GROUP=$USERNAME

USER $USERNAME:$USERNAME
WORKDIR "/home/$USERNAME"
# Pin HOME explicitly: `docker run -u <host-uid>:<host-gid>` (used to avoid
# root-owned output files) puts the container under a uid with no /etc/passwd
# entry, so HOME would otherwise default to "/" and Python couldn't find the
# torch/etc. packages that pip installed to ~/.local via PIP_USER=1 below.
ENV HOME="/home/$USERNAME"
ENV PATH="/home/$USERNAME/.local/bin:${PATH}"
ENV PYTHONPATH="/home/$USERNAME/project"
# pip has no writable system site-packages as this non-root user, so install
# everything to the user site (~/.local) instead of passing --user everywhere
ENV PIP_USER=1

RUN pip3 install -U pip
# CPU-only wheels: no CUDA runtime/driver is required to build or run this image
RUN pip3 install torch==1.8.1+cpu torchvision==0.9.1+cpu \
    -f https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install numpy==1.23.5 scipy opencv-python-headless joblib matplotlib pandas \
    albumentations==0.5.2 pytorch-lightning==1.2.9 tabulate easydict==1.9.0 kornia==0.5.0 webdataset \
    packaging tqdm pyyaml hydra-core==1.1.0 scikit-learn==0.24.2 tabulate
RUN pip3 install scikit-image==0.17.2

ENV TORCH_HOME="/home/$USERNAME/.torch"
ENV CUDA_VISIBLE_DEVICES=""

# pip (PIP_USER=1) creates ~/.local, and nested dirs like site-packages, as 700,
# which blocks traversal/reads for any uid other than $USERNAME's (e.g.
# `docker run -u $(id -u):$(id -g)`). Open it up recursively -- a+rX adds
# read to all files and execute/traversal only to dirs (and files already
# executable), so script permissions aren't altered -- so both entrypoint.sh
# and the installed packages stay reachable regardless of runtime uid.
RUN chmod -R a+rX /home/$USERNAME/.local

ADD entrypoint.sh /home/$USERNAME/.local/bin/entrypoint.sh
ENTRYPOINT [ "entrypoint.sh" ]
