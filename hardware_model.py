from dataclasses import dataclass, field

@dataclass
class ErrorCode:
    device: str
    component: str
    symptoms: list[str]
    failed_fixes: list[str] = field(default_factory=list)

class Component:
    def __init__(self, name):
        self.name = name
        self.state = "UNKNOWN"
        self.symptoms = []

    def set_state(self, state):
        self.state = state

    def add_symptom(self, symptom):
        self.symptoms.append(symptom)

    def __str__(self):
        return f"{self.name} | State: {self.state} | Symptoms: {self.symptoms}"

class PowerComponent(Component):
    def __init__(self):
        super().__init__("power")

class ConnectivityComponent(Component):
    def __init__(self):
        super().__init__("connectivity")

class InternalComponent(Component):
    def __init__(self):
        super().__init__("internal")

class Device:
    def __init__(self, name):
        self.name = name
        self.components = []

    def add_component(self, component):
        self.components.append(component)

    def get_error_code(self):
        """
        Converts the current device state into ErrorCode objects for diagnosis.
        """
        error_list = []

        for comp in self.components:
            if comp.symptoms:
                error = ErrorCode(
                    device=self.name,
                    component=comp.name,
                    symptoms=comp.symptoms,
                    failed_fixes=[]
                )
                error_list.append(error)

        return error_list

    def __str__(self):
        output = f"\nDevice: {self.name}\n" + "-" * 30 + "\n"
        for comp in self.components:
            output += str(comp) + "\n"
        return output