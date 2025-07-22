#ifndef VAT_INCLUDED
#define VAT_INCLUDED

#include "ConstantBuffer/MaterialDynamic.hlsl"

bool IsVATEnabled()
{
	return u_vat_type.x > 0;
}

#endif