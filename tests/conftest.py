"""Shared pytest fixtures and configuration."""

import os
import tempfile
import shutil
from pathlib import Path
from typing import Generator, Dict, Any
import pytest


@pytest.fixture
def temp_dir() -> Generator[Path, None, None]:
    """Create a temporary directory for testing."""
    temp_path = tempfile.mkdtemp()
    yield Path(temp_path)
    shutil.rmtree(temp_path)


@pytest.fixture
def sample_hosts_file(temp_dir: Path) -> Path:
    """Create a sample hosts file for testing."""
    hosts_path = temp_dir / "hosts"
    hosts_content = """# Sample hosts file
127.0.0.1 localhost
0.0.0.0 ad.doubleclick.net
0.0.0.0 googleads.g.doubleclick.net

# Duplicate entry
0.0.0.0 ad.doubleclick.net
"""
    hosts_path.write_text(hosts_content)
    return hosts_path


@pytest.fixture
def sample_dnsmasq_file(temp_dir: Path) -> Path:
    """Create a sample dnsmasq file for testing."""
    dnsmasq_path = temp_dir / "dnsmasq"
    dnsmasq_content = """# Sample dnsmasq configuration
config domain
    option name 'ad.example.com'
    option ip '0.0.0.0'

config domain
    option name 'tracker.example.com'
    option ip '0.0.0.0'

# Duplicate entry
config domain
    option name 'ad.example.com'
    option ip '0.0.0.0'
"""
    dnsmasq_path.write_text(dnsmasq_content)
    return dnsmasq_path


@pytest.fixture
def sample_pihole_file(temp_dir: Path) -> Path:
    """Create a sample Pi-hole blocklist file for testing."""
    pihole_path = temp_dir / "pihole.txt"
    pihole_content = """ad.doubleclick.net
googleads.g.doubleclick.net
tracker.example.com
analytics.example.com
ad.doubleclick.net
"""
    pihole_path.write_text(pihole_content)
    return pihole_path


@pytest.fixture
def mock_args() -> Dict[str, Any]:
    """Provide mock command line arguments."""
    return {
        "add": None,
        "check_duplicates": False,
        "remove_duplicates": False,
    }


@pytest.fixture
def sample_tracked_files(temp_dir: Path, sample_hosts_file: Path, 
                        sample_dnsmasq_file: Path, sample_pihole_file: Path) -> list:
    """Create a set of tracked files for testing."""
    return [
        (str(sample_hosts_file), True),
        (str(sample_dnsmasq_file), True),
        (str(sample_pihole_file), False)
    ]


@pytest.fixture(autouse=True)
def change_test_dir(temp_dir: Path, monkeypatch):
    """Change to temporary directory for each test."""
    monkeypatch.chdir(temp_dir)


@pytest.fixture
def isolated_environment(monkeypatch):
    """Create an isolated environment for testing."""
    # Clear any existing environment variables that might affect tests
    env_vars_to_clear = ["PYTHONPATH", "PYTEST_CURRENT_TEST"]
    for var in env_vars_to_clear:
        monkeypatch.delenv(var, raising=False)
    
    # Set a clean PATH
    monkeypatch.setenv("PATH", os.environ.get("PATH", ""))


@pytest.fixture
def mock_file_not_found():
    """Mock FileNotFoundError for testing error handling."""
    def _mock_file_not_found(filename: str):
        raise FileNotFoundError(f"File '{filename}' not found")
    return _mock_file_not_found


@pytest.fixture
def capture_print(monkeypatch):
    """Capture print statements for testing."""
    captured = []
    
    def mock_print(*args, **kwargs):
        captured.append(" ".join(str(arg) for arg in args))
    
    monkeypatch.setattr("builtins.print", mock_print)
    return captured