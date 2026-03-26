#!/bin/python3
from subprocess import run
from textwrap import dedent

errors = []
def printerr():
    for i, err in enumerate(errors):
        print(f"[{i + 1}] ".ljust(30, '-'))
        print(err)


def exec(cmd: list[str]):
    res = run(cmd, capture_output=True, text=True)
    return res.returncode, res.stdout if res.returncode == 0 else res.stderr


def get_node_list():
    global errors
    nodes = {
        "master": [],
        "worker": []
    }

    # Get node info
    res, out = exec(["kubectl", "get", "node", "-o", "wide"])
    if res != 0:
        errors.append(out)
    else:
        lines = out.splitlines()
        for line in lines[1:]:
            name, status, role, _, _, address, *_ = line.split()
            role = "master" if "control-plane" in role else "worker"
            nodes[role].append({
                "name": name,
                "status": status,
                "address": address
            })

        # Sort by address
        for ntype in nodes:
            nodes[ntype].sort(key=lambda x: x["address"])

    return nodes


def retire_node(node: str):
    global errors
    res, out = exec(["kubectl", "drain", "--ignore-daemonsets", "--delete-emptydir-data", node])
    if res != 0:
        errors.append(out)
        return

    res, out = exec(["kubectl", "taint", "nodes", node, "retire:NoExecute"])
    if res != 0:
        errors.append(out)


def reinstate_node(node: str):
    global errors
    res, out = exec(["kubectl", "taint", "nodes", node, "retire:NoExecute-"])
    if res != 0:
        errors.append(out)
        return

    res, out = exec(["kubectl", "uncordon", node])
    if res != 0:
        errors.append(out)


def menu(selection: list[str]):
    print(dedent('''\
        [Menu]

        (1) Select node from list
        (2) Retire node
        (3) Reinstate node

        (0) Exit
    '''))
    if len(selection) > 0:
        print("Selected node(s):", selection)

    while True:
        try:
            choice = int(input("Select option: "))
            if choice in range(4):
                return choice
        except:
            pass


def get_node_selection():
    global errors
    errors.clear()
    node_list = get_node_list()
    if len(errors) > 0:
        printerr()
        return []

    print(dedent('''
        [Node list]

        #|Type|Node name|Status|Address
    ''').replace('|', '\t'), end='')

    menu = []
    for k, v in node_list.items():
        for x in v:
            menu.append(x["name"])
            print(len(menu), k, x["name"], x["status"], x["address"], sep='\t')

    while True:
        try:
            choice = [int(x) for x in input("Selection (csv): ").split(',')]
            print()
            return [menu[x - 1] for x in choice]
        except:
            pass


##### Main #####
memory = []
bar = f"\n{'=' * 30}\n"
while True:
    match menu(memory):
        case 0: break
        case 1:
            memory = get_node_selection()
        case 2:
            if len(memory) == 0:
                errors.clear()
                errors.append("Select node from [Menu] before proceeding!")
                printerr()
                print(end=bar)
            else:
                for node in memory:
                    errors.clear()
                    retire_node(node)
                    if len(errors) > 0:
                        printerr()
                        print("Aborting node retirement due to error:", node, end=bar)
                        break
        case 3:
            if len(memory) == 0:
                errors.clear()
                errors.append("Select node from [Menu] before proceeding!")
                printerr()
                print(end=bar)
            else:
                for node in memory:
                    errors.clear()
                    reinstate_node(node)
                    if len(errors) > 0:
                        printerr()
                        print("Aborting node reinstatement due to error:", node, end=bar)
                        break
