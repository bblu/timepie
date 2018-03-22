package tk.bblu.spring.timepie.server;

import java.util.List;
import tk.bblu.spring.timepie.model.Done;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.awt.*;

@RequestMapping(value="/timepie/done")
public class DoneController {
    @RequestMapping(method = RequestMethod.GET)
    public String hello(){
        return "hello timepie server!";
    }


    @RequestMapping(method = RequestMethod.POST,consumes = MediaType.APPLICATION_JSON_VALUE)
    public void postData(@RequestBody List<Done> dones){

    }
}
