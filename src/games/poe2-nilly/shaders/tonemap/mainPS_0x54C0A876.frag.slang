// bridge_shader.hlsl
#include "../../shared.h" // Contains your constant buffer with tone_mapper

struct SPIRV_Cross_Input
{
    float4 gl_FragCoord : SV_Position;
};

struct SPIRV_Cross_Output
{
    float4 out_var_SV_TARGET : SV_Target0;
};

// 1. Rename and include the original vanilla shader
#define main vanilla_main
#include "./mainPS_original.hlsl"
#undef main

// 2. Rename and include your heavily modded shader
#define main modded_main
#include "./mainPS_modded.hlsl"
#undef main

// 3. The actual main entry point that RenoDX compiles
// (Make sure the input signature matches what the game expects, e.g., PS_INPUT)
SPIRV_Cross_Output main(SPIRV_Cross_Input input)
{
    if (RENODX_VANILLA == 1.0f) {
        // Route to the vanilla code
        return mainPS_original::vanilla_main(input);
    } else {
        // Route to your modded code
        return mainPS_modded::modded_main(input);
    }
}