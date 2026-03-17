import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

const FAST2SMS_API_KEY = Deno.env.get("FAST2SMS_API_KEY");

Deno.serve(async (req) => {
  console.log("Function triggered");

  try {
    const payload = await req.text();
    console.log("Payload:", payload);

    const rawSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");

    if (!rawSecret) {
      console.log("Webhook secret missing");
      return new Response(
        JSON.stringify({ error: "Webhook secret missing" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Remove Supabase prefix
    const secret = rawSecret.replace("v1,whsec_", "");

    const headers = Object.fromEntries(req.headers);
    const wh = new Webhook(secret);

    // Verify webhook
    const { user, sms } = wh.verify(payload, headers);

    console.log("Webhook verified");

    const otp = sms.otp;
    const phone = user.phone;

    console.log("Phone:", phone);
    console.log("OTP:", otp);

    // Convert to 10 digit number
    const mobile = phone.slice(-10);

    const fast2smsResponse = await fetch(
      "https://www.fast2sms.com/dev/bulkV2",
      {
        method: "POST",
        headers: {
          authorization: FAST2SMS_API_KEY!,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          route: "otp",
          variables_values: otp,
          numbers: mobile,
        }),
      }
    );

    const result = await fast2smsResponse.text();

    console.log("Fast2SMS response:", result);

    // IMPORTANT: return valid JSON response for Supabase
    return new Response(
      JSON.stringify({ success: true }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.log("ERROR OCCURRED:", error);

    return new Response(
      JSON.stringify({
        error: error.toString(),
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});