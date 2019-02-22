package com.apicloud.exif;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Date;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.location.Location;
import android.media.ExifInterface;
import android.text.TextUtils;

import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;
import com.uzmap.pkg.uzkit.UZUtility;

@SuppressLint({ "InlinedApi", "DefaultLocale" }) 
public class ExifInterfaceModule extends UZModule{

	public ExifInterfaceModule(UZWebView webView) {
		super(webView);
	}

	public void jsmethod_setExifInfo(final UZModuleContext moduleContext){
		(new Thread(new Runnable() {
			public void run() {
				String _picPath = moduleContext.optString("picPath");
				Double latitude =  moduleContext.optDouble("latitude",0.0);
				Double longitude = moduleContext.optDouble("longitude",0.0);
				if(TextUtils.isEmpty(_picPath)){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "处理图片不能为空");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				String ext = _picPath.substring(_picPath.lastIndexOf(".")+1, _picPath.length()).toLowerCase();
				if(!"jpg".equals(ext) && !"jpeg".equals(ext) ){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "仅支持jpg和jpeg图片处理!");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				String picPath = makeRealPath(_picPath);
				if(!fileIsExists(picPath)){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "文件不存在");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				try {
					// 获取图片前缀
					ExifInterface exif = new ExifInterface(picPath);
					// 写入经度信息
					exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE,gpsInfoConvert(longitude));
					exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF,longitude > 0 ? "E" : "W");
//					 写入纬度信息
					exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE,gpsInfoConvert(latitude));
					exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF,latitude > 0 ? "N" : "S");
//					 执行保存
					exif.saveAttributes();
					
					JSONObject ret = new JSONObject();
					try {
						ret.put("status", true);
						
						ret.put("newPicPath", picPath);
						
						String latValue = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE);
				        String latRef = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE_REF);
				        String lngValue = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE);
				        String lngRef = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF);
				        
				        ret.put("latitude", convertRationalLatLonToFloat(latValue, latRef));
				        ret.put("longitude", convertRationalLatLonToFloat(lngValue, lngRef));
				        
					} catch (Exception e1) {
						e1.printStackTrace();
					}
					moduleContext.success(ret, true);
				} catch (IOException e) {
					e.printStackTrace();
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", e.getMessage());
					} catch (JSONException e1) {
						e1.printStackTrace();
					}
					moduleContext.error(ret, err, false);
				}
			}
		})).start();
	}
	
	
	public void jsmethod_getExifInfo(final UZModuleContext moduleContext){
		
		(new Thread(new Runnable() {
			public void run() {
				final String _picPath = moduleContext.optString("picPath");
				if(TextUtils.isEmpty(_picPath)){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "处理图片不能为空");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				String ext = _picPath.substring(_picPath.lastIndexOf(".")+1, _picPath.length()).toLowerCase();
				if(!"jpg".equals(ext) && !"jpeg".equals(ext) ){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "仅支持jpg和jpeg图片处理!");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				String picPath = makeRealPath(_picPath);
				if(!fileIsExists(picPath)){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "文件不存在");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				try {
					// 获取图片前缀
					ExifInterface exif = new ExifInterface(picPath);
					
					JSONObject ret = new JSONObject();
					try {
						ret.put("status", true);
						
						String latValue = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE);
				        String latRef = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE_REF);
				        String lngValue = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE);
				        String lngRef = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF);
				        
				        ret.put("latitude", convertRationalLatLonToFloat(latValue, latRef));
				        ret.put("longitude", convertRationalLatLonToFloat(lngValue, lngRef));
						
				        //设备型号
//				        String model=exif.getAttribute(ExifInterface.TAG_MODEL);
//				        //设备制造商
//				        String make=exif.getAttribute(ExifInterface.TAG_MAKE);
				        //图片宽
//				        String width=exif.getAttribute(ExifInterface.TAG_IMAGE_WIDTH);
//				        //图片长
//			            String height=exif.getAttribute(ExifInterface.TAG_IMAGE_LENGTH);
			            //时间日期
//			            String datetime=exif.getAttribute(ExifInterface.TAG_DATETIME);
			            
			            
//			            ret.put("model", model);
//			            ret.put("make", make);
//			            ret.put("width", width);
//			            ret.put("height", height);
//			            ret.put("datetime", datetime);
			            
//						int degree = 0;
//						int orientation = exif.getAttributeInt(
//								ExifInterface.TAG_ORIENTATION,
//								ExifInterface.ORIENTATION_NORMAL);
//						switch (orientation) {
//						case ExifInterface.ORIENTATION_ROTATE_90:
//							degree = 90;
//							break;
//						case ExifInterface.ORIENTATION_ROTATE_180:
//							degree = 180;
//							break;
//						case ExifInterface.ORIENTATION_ROTATE_270:
//							degree = 270;
//							break;
//						default:
//							degree = 0;
//						}
						//方向
//	                    ret.put("orientation", orientation);
	                    //旋转角度
//	                    ret.put("degree", degree);
			            
					} catch (Exception e1) {
						e1.printStackTrace();
					}
					moduleContext.success(ret, true);
				} catch (IOException e) {
					e.printStackTrace();
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", e.getMessage());
					} catch (JSONException e1) {
						e1.printStackTrace();
					}
					moduleContext.error(ret, err, false);
				}
			}
		})).start();
	}
	
	public void jsmethod_setDegreeExif(final UZModuleContext moduleContext){
		(new Thread(new Runnable() {
			public void run() {
				String _picPath = moduleContext.optString("picPath");
				boolean isDelete = moduleContext.optBoolean("isDelete", false);
				int degrees =  moduleContext.optInt("degrees", 0);
				if(TextUtils.isEmpty(_picPath)){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "处理图片不能为空");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				String ext = _picPath.substring(_picPath.lastIndexOf(".")+1, _picPath.length()).toLowerCase();
				if(!"jpg".equals(ext) && !"jpeg".equals(ext) ){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "仅支持jpg和jpeg图片处理!");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				String picPath = makeRealPath(_picPath);
				if(_picPath.startsWith("widget://")){
					if(!UZUtility.assetFileExists(picPath)){
						JSONObject ret = new JSONObject();
						JSONObject err = new JSONObject();
						try {
							ret.put("status", false);
							
							err.put("msg", "文件不存在");
						} catch (JSONException e) {
							e.printStackTrace();
						}
						moduleContext.error(ret, err, false);
						return;
					}
					
					OutputStream os = null;
					
					try {
						InputStream in = UZUtility.guessInputStream(picPath);
						String temp = UZUtility.getExternalCacheDir()+picPath.substring(picPath.lastIndexOf("/")+1, picPath.length());
						
						File file = new File(temp);
						os = new FileOutputStream(file);
						int ch = 0;
						while ((ch = in.read()) != -1) {
							os.write(ch);
						}
						os.flush();
						picPath = temp;
					} catch (IOException e) {
						e.printStackTrace();
						
						JSONObject ret = new JSONObject();
						JSONObject err = new JSONObject();
						try {
							ret.put("status", false);
							
							err.put("msg", "文件不存在");
						} catch (JSONException e1) {
						}
						moduleContext.error(ret, err, false);
						return;
					}finally {
						try {
							os.close();
						} catch (Exception e2) {
							e2.printStackTrace();
						}
					}
				}else if(!fileIsExists(picPath)){
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", "文件不存在");
					} catch (JSONException e) {
						e.printStackTrace();
					}
					moduleContext.error(ret, err, false);
					return;
				}
				
				try {
					Bitmap bitmap = BitmapFactory.decodeFile(picPath);
					if (null == bitmap) {
						JSONObject ret = new JSONObject();
						JSONObject err = new JSONObject();
						try {
							ret.put("status", false);
							
							err.put("msg", "文件不存在");
						} catch (JSONException e) {
							e.printStackTrace();
						}
						moduleContext.error(ret, err, false);
						return;
					}
					
					if(degrees!=90 && degrees!=180 && degrees!=270){
						degrees = 0;
					}
					
					if (degrees == 0) {
						JSONObject ret = new JSONObject();
						try {
							ret.put("status", true);
							ret.put("newPicPath", picPath);
						} catch (Exception e1) {
							e1.printStackTrace();
						}
						moduleContext.success(ret, true);
						return;
					}
					//获取旋转前的经纬度信息
					ExifInterface exif = new ExifInterface(picPath);
					String latValue = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE);
			        String latRef = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE_REF);
			        String lngValue = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE);
			        String lngRef = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF);
			        //end
			        
			        //创建一个与bitmap一样大小的bitmap2
			        Bitmap bitmap2 = rotate(bitmap, degrees);
					
					//转换后文件处理
					String fileName = new Date().getTime()+picPath.substring(picPath.lastIndexOf("."), picPath.length());
					
					String newPicPath = UZUtility.getExternalCacheDir()+fileName;
					File file = new File(newPicPath);
					if(file.exists()){
						file.delete();
					}
					FileOutputStream out = new FileOutputStream(file);
					bitmap2.compress(Bitmap.CompressFormat.JPEG, 90, out);
					out.flush();
					out.close();
					
					if(isDelete){
						File file1 = new File(picPath);
						if(file1.exists()){
							file1.delete();
						}
					}
					
					//旋转后，将经纬度信息重新写入新文件
					
					// 获取图片前缀
					ExifInterface newExif = new ExifInterface(newPicPath);
					// 写入经度信息
					newExif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE,lngValue);
					newExif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF,lngRef);
//					 写入纬度信息
					newExif.setAttribute(ExifInterface.TAG_GPS_LATITUDE,latValue);
					newExif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF,latRef);
					newExif.saveAttributes();
					//end
					
					JSONObject ret = new JSONObject();
					try {
						ret.put("status", true);
						ret.put("newPicPath", newPicPath);
					} catch (Exception e1) {
						e1.printStackTrace();
					}
					moduleContext.success(ret, true);
				} catch (IOException e) {
					e.printStackTrace();
					JSONObject ret = new JSONObject();
					JSONObject err = new JSONObject();
					try {
						ret.put("status", false);
						
						err.put("msg", e.getMessage());
					} catch (JSONException e1) {
						e1.printStackTrace();
					}
					moduleContext.error(ret, err, false);
				}
				
//				try {
//					ExifInterface exif = new ExifInterface(picPath);
//					if(degrees == 90){
//						exif.setAttribute(ExifInterface.TAG_ORIENTATION,String.valueOf(ExifInterface.ORIENTATION_ROTATE_90));
//					}else if(degrees == 180){
//						exif.setAttribute(ExifInterface.TAG_ORIENTATION,String.valueOf(ExifInterface.ORIENTATION_ROTATE_180));
//					}else if(degrees == 270){
//						exif.setAttribute(ExifInterface.TAG_ORIENTATION,String.valueOf(ExifInterface.ORIENTATION_ROTATE_270));
//					}else {
//						exif.setAttribute(ExifInterface.TAG_ORIENTATION,String.valueOf(ExifInterface.ORIENTATION_NORMAL));
//					}
//					exif.saveAttributes();
//					
//					JSONObject ret = new JSONObject();
//					try {
//						ret.put("status", true);
//						ret.put("newPicPath", picPath);
//					} catch (Exception e1) {
//						e1.printStackTrace();
//					}
//					moduleContext.success(ret, true);
//				} catch (IOException e) {
//					e.printStackTrace();
//					JSONObject ret = new JSONObject();
//					JSONObject err = new JSONObject();
//					try {
//						ret.put("status", false);
//						
//						err.put("msg", e.getMessage());
//					} catch (JSONException e1) {
//						e1.printStackTrace();
//					}
//					moduleContext.error(ret, err, false);
//				}
			}
		})).start();
	}
	
	public boolean fileIsExists(String path) {
		File f;
		try {
			f = new File(path);
			if (f.exists()) {
				return true;
			} else {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
	}
	
	
	private String gpsInfoConvert(double gpsInfo) {
		gpsInfo = Math.abs(gpsInfo);
		String dms = Location.convert(gpsInfo, Location.FORMAT_SECONDS);
		String[] splits = dms.split(":");
		String[] secnds = (splits[2]).split("\\.");
		String seconds;
		if (secnds.length == 0) {
			seconds = splits[2];
		} else {
			seconds = secnds[0]+secnds[1];
		}
		return splits[0] + "/1," + splits[1] + "/1," + seconds + "/1000";
	}
	
	
	private static float convertRationalLatLonToFloat(
            String rationalString, String ref) {
        try {
            String [] parts = rationalString.split(",");


            String [] pair;
            pair = parts[0].split("/");
            int degrees = (int) (Float.parseFloat(pair[0].trim())
                    / Float.parseFloat(pair[1].trim()));


            pair = parts[1].split("/");
            int minutes = (int) ((Float.parseFloat(pair[0].trim())
                    / Float.parseFloat(pair[1].trim())));


            pair = parts[2].split("/");
            float seconds = Float.parseFloat(pair[0].trim())
                    / Float.parseFloat(pair[1].trim());


            float result = degrees + (minutes / 60F) + (seconds / (60F * 60F));
            if ((ref.equals("S") || ref.equals("W"))) {
                return -result;
            }
            return result;
        } catch (RuntimeException ex) {
            // if for whatever reason we can't parse the lat long then return
            // null
            return 0f;
        }
    }
	
	public static Bitmap rotate(Bitmap b, int degrees) {
		if (degrees != 0 && b != null) {
			Matrix m = new Matrix();
			m.setRotate(degrees,(float) b.getWidth() / 2, (float) b.getHeight() / 2);
			try {
				Bitmap b2 = Bitmap.createBitmap(b, 0, 0, b.getWidth(), b.getHeight(), m, true);
				if (b != b2) {
					b.recycle(); // Android开发网再次提示Bitmap操作完应该显示的释放
					b = b2;
				}
			} catch (OutOfMemoryError ex) {
				// 建议大家如何出现了内存不足异常，最好return 原始的bitmap对象。.
				return b;
			}
		}
		return b;

	}
}
