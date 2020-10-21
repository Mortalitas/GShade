namespace pkd {

    namespace Color {
        namespace CIELAB {

            // Functions for working in the CIE L*a*b colorspace.
            //
            // For purposes of storing color, CIELAB is stored in float3 with
            // x = L, y = A, z = B.

            // Internal helper functions
            float __LAB1(float orig)
            {
                if (orig > 0.04045) {
                    return pow(abs((orig + 0.55) / 1.055), 2.4);
                }
                else {
                    return orig / 12.92;
                }
            }

            float __LAB2(float orig)
            {
                if (orig > 0.008856) {
                    return pow(abs(orig), 1.0/3);
                }
                else {
                    return (7.787 * orig) * 15.0 / 116.0;
                }
            }

            float __LAB3(float orig)
            {
                if (orig * orig * orig > 0.008856) {
                    return orig * orig * orig;
                }
                else {
                    return (orig - 16.0 / 116.0) / 7.787;
                }
            }

            float __LAB4(float orig)
            {
                if (orig > 0.0031308) {
                    return (1.055 * pow(abs(orig), 1 / 2.4) - 0.055);
                }
                else {
                    return 12.92 * orig;
                }
            }

            float3 RGB2LAB(float3 color) 
            {
                float rt, gt, bt;
                float x, y, z;

                rt = __LAB1(color.r);
                gt = __LAB1(color.g);
                bt = __LAB1(color.b);

                x = (rt * 0.4124 + gt * 0.3576 + bt * 0.1805) / 0.95047;
                y = (rt * 0.2126 + gt * 0.7152 + bt * 0.0722) / 1.00000;
                z = (rt * 0.0193 + gt * 0.1192 + bt * 0.9505) / 1.08883;

                x = __LAB2(x);
                y = __LAB2(y);
                z = __LAB2(z);

                return float3((116.0 * y) - 16, 500 * (x - y), 200 * (y - z));
            }

            float3 LAB2RGB(float3 color)
            {
                float r, g, b;

                float y = (color.x + 16) / 116;
                float x = color.y / 500 + y;
                float z = y - color.z / 200;

                x = 0.95047 * __LAB3(x);
                y = __LAB3(y);
                z = 1.08883 * __LAB3(z);

                r = x *  3.2406 + y * -1.5372 + z * -0.4986;
                g = x * -0.9689 + y *  1.8758 + z *  0.0415;
                b = x *  0.0557 + y * -0.2040 + z *  1.0570;

                r = clamp(__LAB4(r), 0., 1.);
                g = clamp(__LAB4(g), 0., 1.);
                b = clamp(__LAB4(b), 0., 1.);

                return float3(r, g, b);
            }

            float DeltaE(float3 lab1, float3 lab2)
            {
                const float3 delta = lab1 - lab2;

                const float c1 = sqrt(lab1.y * lab1.y * lab1.z * lab1.z);
                const float c2 = sqrt(lab2.y * lab2.y * lab2.z * lab2.z);

                const float deltaC = c1 - c2;
                float deltaH = delta.y * delta.y + delta.z * delta.z - deltaC * deltaC;
                if (deltaH < 0) {
                    deltaH = 0;
                }
                else {
                    deltaH = sqrt(deltaH);
                }
                const float deltaCkcsc = deltaC / (1.0 + 0.045 * c1);
                const float deltaHkhsh = deltaH / (1.0 + 0.015 * c1);
                const float colorDelta = delta.x * delta.x + deltaCkcsc * deltaCkcsc + deltaHkhsh * deltaHkhsh;
                if (colorDelta < 0) {
                    return 0;
                }
                else {
                    return sqrt(colorDelta);
                }
            }
        }

        float DeltaRGB( in float3 RGB1, in float3 RGB2 )
        {
            return pkd::Color::CIELAB::DeltaE(pkd::Color::CIELAB::RGB2LAB(RGB1), pkd::Color::CIELAB::RGB2LAB(RGB2));
        }

        float3 HUEToRGB( in float H )
        {
            return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
                                          2.0f - abs( H * 6.0f - 2.0f ),
                                          2.0f - abs( H * 6.0f - 4.0f )));
        }        

        float3 RGBToHCV( in float3 RGB )
        {
            // Based on work by Sam Hocevar and Emil Persson
            float4 P;
            if ( RGB.g < RGB.b ) {
                P = float4( RGB.bg, -1.0f, 2.0f/3.0f );
            }
            else {
                P = float4( RGB.gb, 0.0f, -1.0f/3.0f );
            }

            float4 Q1;
            if ( RGB.r < P.x ) {
                Q1 = float4( P.xyw, RGB.r );
            }
            else {
                Q1 = float4( RGB.r, P.yzx );
            }

            const float C = Q1.x - min( Q1.w, Q1.y );

            return float3( abs(( Q1.w - Q1.y ) / ( 6.0f * C + 0.000001f ) + Q1.z ), C, Q1.x );
        }

        float3 RGBToHSL( in float3 RGB )
        {
            RGB.xyz          = max( RGB.xyz, 0.000001f );
            const float3 HCV       = RGBToHCV(RGB);
            const float L          = HCV.z - HCV.y * 0.5f;
            return float3( HCV.x, HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f), L );
        }

        float3 HSLToRGB( in float3 HSL )
        {
            return ( HUEToRGB(HSL.x) - 0.5f ) * ((1.0f - abs(2.0f * HSL.z - 1.0f)) * HSL.y) + HSL.z;
        }

        // Collected from
        // http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
        float3 RGBToHSV(float3 c)
        {
            const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

            float4 p;
            if (c.g < c.b) {
                p = float4(c.bg, K.wz);
            }
            else {
                p = float4(c.gb, K.xy);
            }

            float4 q;
            if (c.r < p.x) {
                q = float4(p.xyw, c.r);
            }
            else {
                q = float4(c.r, p.yzx);
            }

            const float d = q.x - min(q.w, q.y);
            const float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        float3 HSVToRGB(float3 c)
        {
            const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            return c.z * lerp(K.xxx, saturate(abs(frac(c.xxx + K.xyz) * 6.0 - K.www) - K.xxx), c.y);
        }
    }

}