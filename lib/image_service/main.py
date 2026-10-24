
from io import BytesIO
from fastapi.middleware.cors import CORSMiddleware

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import Response
from PIL import Image, ImageOps
from rembg import remove

app = FastAPI(title="Stylr Image Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["null", "http://127.0.0.1:5500", "http://localhost:5500"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MAX_FILE_SIZE = 10 * 1024 * 1024
CANVAS_SIZE = 1024
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}


@app.get("/health")
def health():
    return {"status": "ok", "service": "stylr-image-service"}


@app.post("/image/remove-background")
async def remove_background(file: UploadFile = File(...)):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Upload a JPEG, PNG, or WebP image.",
        )

    try:
        image_bytes = await file.read(MAX_FILE_SIZE + 1)

        if not image_bytes:
            raise HTTPException(status_code=400, detail="Image is empty.")

        if len(image_bytes) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=413,
                detail="Image must be 10 MB or smaller.",
            )

        # Validate and normalize the uploaded image.
        with Image.open(BytesIO(image_bytes)) as source:
            source = ImageOps.exif_transpose(source)
            source.load()
            normalized = source.convert("RGBA")

        # Remove the background using the CPU inference backend.
        
        input_buffer = BytesIO()
        normalized.save(input_buffer, format="PNG")
        input_bytes = input_buffer.getvalue()

        # Remove the background.
        cutout_bytes = remove(input_bytes)

        with Image.open(BytesIO(cutout_bytes)) as result:
            cutout = result.convert("RGBA")


        # Crop transparent margins around the clothing.
        alpha = cutout.getchannel("A")
        bounds = alpha.getbbox()

        if bounds is None:
            raise HTTPException(
                status_code=422,
                detail="No foreground object was detected.",
            )

        cutout = cutout.crop(bounds)

        # Fit the item onto a white square canvas without distortion.
        cutout.thumbnail((CANVAS_SIZE - 100, CANVAS_SIZE - 100))

        canvas = Image.new(
            "RGBA",
            (CANVAS_SIZE, CANVAS_SIZE),
            (255, 255, 255, 255),
        )

        x = (CANVAS_SIZE - cutout.width) // 2
        y = (CANVAS_SIZE - cutout.height) // 2

        canvas.alpha_composite(cutout, (x, y))

        output = BytesIO()
        canvas.convert("RGB").save(
            output,
            format="PNG",
            optimize=True,
        )

        return Response(
            content=output.getvalue(),
            media_type="image/png",
            headers={
                "Content-Disposition": 'inline; filename="stylr-clean.png"'
            },
        )

    except HTTPException:
        raise
    except Exception as error:
        print(f"Image processing failed: {error}")
        raise HTTPException(
            status_code=500,
            detail="Image processing failed. Please try another image.",
        ) from error
    finally:
        await file.close()
