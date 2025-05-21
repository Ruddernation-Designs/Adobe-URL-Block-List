from argparse import ArgumentParser

parser = ArgumentParser()

parser.add_argument("-i", "--add", type=str)
parser.add_argument("-RD", "--remove-duplicates",
                    action="store_true", default=False)

args = parser.parse_args()


def read_stripped(file: str):
    try:
        with open(file, "r") as f:
            strip_comments = [l.strip()
                              if not l.startswith("#") else None
                              for l in f.readlines()]

            return list(filter(None, strip_comments))

    except FileNotFoundError as e:
        raise e


def dnsmasq_fmt(*domains):
    space_indent = " "*2*4

    domain_list = [f"config domain\n{space_indent}option name '{domain}'\n{space_indent}option ip '0.0.0.0'\n"
                   for domain in domains]

    return "\n".join(domain_list)


def main():
    hosts_record = read_stripped("hosts")
    dnsmasq_record = read_stripped("dnsmasq")


if __name__ == "__main__":
    main()
