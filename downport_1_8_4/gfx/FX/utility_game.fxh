Code
[[
	float Hash1D( float2 p )
	{
		p = frac( p * 0.3183099 + 0.1 );
		p *= 17.0;
		return frac( p.x * p.y * ( p.x + p.y ) );
	}

	float3 Hash3D( float3 p3 )
	{
			p3 = frac( p3 * float3( 0.2818, 0.1656, 0.1543 ) );
			p3 += dot( p3, p3.yxz + 19.19 );
			return -1.0 + 2.0 * frac( float3( ( p3.x + p3.y ) * p3.z, ( p3.x + p3.z ) * p3.y, ( p3.y + p3.z ) * p3.x ) );
	}

	float simplex3D( float3 p )
	{

		const float K1 = 0.333333333;
		const float K2 = 0.166666667;

		float3 i = floor( p + ( p.x + p.y + p.z ) * K1 );
		float3 d0 = p - ( i - ( i.x + i.y + i.z ) * K2 );

		float3 e = step( vec3( 0.0 ), d0 - d0.yzx );
		float3 i1 = e * (1.0 - e.zxy);
		float3 i2 = 1.0 - e.zxy * ( 1.0 - e );

		float3 d1 = d0 - ( i1 - 1.0 * K2 );
		float3 d2 = d0 - ( i2 - 2.0 * K2 );
		float3 d3 = d0 - ( 1.0 - 3.0 * K2 );

		float4 h = max( 0.6 - float4( dot( d0, d0 ), dot( d1, d1 ), dot( d2, d2 ), dot( d3, d3 ) ), 0.0 );
		float4 n = h * h * h * h * float4( dot( d0, Hash3D( i ) ), dot( d1, Hash3D( i + i1 ) ), dot( d2, Hash3D( i + i2 ) ), dot( d3, Hash3D( i + 1.0 ) ) );

		return dot( vec4( 31.316 ), n );
	}

	float fbm( float3 p )
	{
		float f;
		f  = 0.50000 * simplex3D( p ); p = p * 2.01;
		f += 0.25000 * simplex3D( p ); p = p * 2.02;
		f += 0.12500 * simplex3D( p ); p = p * 2.03;
		f += 0.06250 * simplex3D( p ); p = p * 2.04;
		f += 0.03125 * simplex3D( p );

		return f;
	}
]]
