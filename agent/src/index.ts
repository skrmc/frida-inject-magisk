import "frida-il2cpp-bridge";

Il2Cpp.perform(() => {
  Il2Cpp.trace()
    .assemblies(Il2Cpp.domain.assembly("Assembly-CSharp"))
    .and()
    .attach();
});
