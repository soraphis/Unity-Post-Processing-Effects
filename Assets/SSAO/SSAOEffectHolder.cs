using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

[ExecuteInEditMode]
public class SSAOEffectHolder : MonoBehaviour {
    public Shader SSAO;
    private Material material;

    private List<Vector4> samples;

    [SerializeField] private bool noBlur = false;
    [SerializeField] private bool debug = false;
    [Range(0, 1)][SerializeField] private float kernelSize = 0.02f;
    [Range(0, 1)][SerializeField] private float bias = 0.3f;
    [Range(0, 10)][SerializeField] private float intensity = 1f;
    [Range(0, 10)][SerializeField] private float blurOffset = 1.5f;
    
    [Range(1, 256)][SerializeField] private int sampleCount = 4;
    private int _sampleCount = -1;
    
    // Creates a private material used to the effect
    private void OnValidate() {
        Awake();
    }

    void Awake() {
        if (SSAO == null) {
            Shader.Find("Hidden/SSAO");
            if (SSAO == null) {
                this.enabled = false;
                return;
            }
            this.material = new Material(SSAO);
        }
        if (material == null) {
            this.material = new Material(SSAO);
        }
        samples = new List<Vector4>(sampleCount);
    }

    void DoInit() {
        _sampleCount = sampleCount;
        for (int i = 0; i < sampleCount; ++i) {
            var v = Random.insideUnitSphere;
            samples.Add(v);
        }
        
        Vector2 vec = new Vector3();
    }

    // Postprocess the image
    void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (_sampleCount != sampleCount || samples.Count != sampleCount) DoInit();
        material.SetVectorArray("_Samples", samples);
        material.SetFloat("_SampleCount", _sampleCount);
        
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;

        material.SetFloat("_Debug", debug ? 1.0f : 0.0f);
        material.SetFloat("_KernelSize", kernelSize);
        material.SetFloat("_BIAS", bias);
        material.SetFloat("_Intensity", intensity);
        
        
        var tmp = RenderTexture.GetTemporary(Screen.width, Screen.height);
        var tmp1 = RenderTexture.GetTemporary(Screen.width, Screen.height);

        Graphics.Blit(source, tmp, material, 0);
        
        if (noBlur) {
            material.SetTexture("_OcclusionTexture", tmp);
        } else {
            material.SetFloat("_BlurOffset", blurOffset);
            for(int i = 0; i < 2; ++i){ // multiple blur passes (in this case 2*2)
                Graphics.Blit(tmp, tmp1, material, 1);
                Graphics.Blit(tmp1, tmp, material, 1);
            }
            material.SetTexture("_OcclusionTexture", tmp);
        }        
        Graphics.Blit(source, destination, material, 2);
        
        RenderTexture.ReleaseTemporary(tmp);
        RenderTexture.ReleaseTemporary(tmp1);
    }

}