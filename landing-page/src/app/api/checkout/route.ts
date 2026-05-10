import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { audienceId, email, tier = 'gold', anonymous_uuid = 'anonymous' } = body;

    // Backend URL (FastAPI)
    const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    
    // Call our FastAPI backend to generate a YooKassa payment URL
    const response = await fetch(`${backendUrl}/api/v1/subscription/payments/create`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tier: tier,
        amount: 1.00, // Example trial amount
        anonymous_uuid: anonymous_uuid
      }),
    });

    if (!response.ok) {
      console.error('Failed to create payment on backend:', await response.text());
      return NextResponse.json(
        { error: 'Payment creation failed on backend' },
        { status: 500 }
      );
    }

    const data = await response.json();
    
    // data should contain { payment_url: "...", payment_id: "..." }
    return NextResponse.json({
      url: data.payment_url,
      paymentId: data.payment_id
    });

  } catch (error) {
    console.error('Error in /api/checkout:', error);
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    );
  }
}
